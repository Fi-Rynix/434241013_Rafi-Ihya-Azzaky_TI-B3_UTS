-- ================================================
-- E-Ticketing Helpdesk Database Schema
-- Target: Supabase Postgres
-- Version: 3.0
-- ================================================

-- ================================================
-- 1. ENUMS
-- ================================================

CREATE TYPE user_role AS ENUM ('user', 'admin', 'helpdesk');

CREATE TYPE ticket_status AS ENUM (
  'open',
  'assigned',
  'in_progress',
  'pending_unassign',
  'done',
  'cancelled'
);

CREATE TYPE notif_type AS ENUM (
  'ticket_created',
  'ticket_assigned',
  'ticket_reassigned',
  'ticket_unassigned',
  'ticket_unassign_requested',
  'ticket_unassign_approved',
  'ticket_unassign_rejected',
  'ticket_in_progress',
  'ticket_done',
  'ticket_cancelled',
  'ticket_edited',
  'comment_added',
  'helpdesk_availability_changed'
);

-- ================================================
-- 2. USERS (extend auth.users)
-- ================================================

CREATE TABLE users (
  id_user INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'user',
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Auto-create user on Supabase Auth signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_username TEXT;
BEGIN
  v_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    split_part(NEW.email, '@', 1)
  );

  INSERT INTO public.users (auth_user_id, username, role)
  VALUES (NEW.id, v_username, 'user');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- ================================================
-- 3. HELPDESKS
-- ================================================

CREATE TABLE helpdesks (
  id_helpdesk INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_user INT UNIQUE REFERENCES users(id_user) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  is_available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_helpdesks_is_available ON helpdesks(is_available);

-- ================================================
-- 4. TICKETS
-- ================================================

CREATE TABLE tickets (
  id_ticket INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status ticket_status NOT NULL DEFAULT 'open',

  id_user INT REFERENCES users(id_user) ON DELETE SET NULL,
  id_helpdesk INT REFERENCES helpdesks(id_helpdesk) ON DELETE SET NULL,

  photo_path TEXT,

  cancelled_reason TEXT,
  cancelled_at TIMESTAMPTZ,

  unassign_id_helpdesk INT REFERENCES helpdesks(id_helpdesk) ON DELETE SET NULL,
  unassign_requested_at TIMESTAMPTZ,
  unassign_reason TEXT,
  unassign_id_user INT REFERENCES users(id_user) ON DELETE SET NULL,
  unassign_decided_at TIMESTAMPTZ,
  unassign_reject_reason TEXT,

  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_id_user ON tickets(id_user);
CREATE INDEX idx_tickets_id_helpdesk ON tickets(id_helpdesk);
CREATE INDEX idx_tickets_created_at_desc ON tickets(created_at DESC);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

-- ================================================
-- 5. COMMENTS
-- ================================================

CREATE TABLE comments (
  id_comment INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_ticket INT REFERENCES tickets(id_ticket) ON DELETE CASCADE NOT NULL,
  id_user INT REFERENCES users(id_user) ON DELETE SET NULL,
  message TEXT NOT NULL,
  is_edited BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_id_ticket_created_at ON comments(id_ticket, created_at ASC);

CREATE TRIGGER trg_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at();

-- ================================================
-- 6. ATTACHMENTS
-- ================================================

CREATE TABLE ticket_attachments (
  id_ticket_attachment INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_ticket INT REFERENCES tickets(id_ticket) ON DELETE CASCADE NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size INT NOT NULL CHECK (file_size <= 5 * 1024 * 1024),
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ticket_attachments_id_ticket ON ticket_attachments(id_ticket);

CREATE TABLE comment_attachments (
  id_comment_attachment INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_comment INT REFERENCES comments(id_comment) ON DELETE CASCADE NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size INT NOT NULL CHECK (file_size <= 5 * 1024 * 1024),
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comment_attachments_id_comment ON comment_attachments(id_comment);

-- Enforce max 3 attachments per comment
CREATE OR REPLACE FUNCTION check_max_attachments()
RETURNS TRIGGER AS $$
DECLARE
  attachment_count INT;
BEGIN
  SELECT COUNT(*) INTO attachment_count
  FROM comment_attachments
  WHERE id_comment = NEW.id_comment;

  IF attachment_count >= 3 THEN
    RAISE EXCEPTION 'Maximum 3 attachments per comment';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_max_attachments
  BEFORE INSERT ON comment_attachments
  FOR EACH ROW EXECUTE PROCEDURE check_max_attachments();

-- ================================================
-- 7. NOTIFICATIONS
-- ================================================

CREATE TABLE notifications (
  id_notification INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_user INT REFERENCES users(id_user) ON DELETE CASCADE NOT NULL,
  type notif_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  id_ticket INT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_id_user_created_at
  ON notifications(id_user, created_at DESC);
CREATE INDEX idx_notifications_id_user_unread
  ON notifications(id_user) WHERE is_read = false;

-- ================================================
-- 8. TICKET LOGS (audit trail)
-- ================================================

CREATE TABLE ticket_logs (
  id_ticket_log INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_ticket INT REFERENCES tickets(id_ticket) ON DELETE CASCADE NOT NULL,
  id_user INT REFERENCES users(id_user) ON DELETE SET NULL,
  actor_role user_role NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ticket_logs_id_ticket_created_at
  ON ticket_logs(id_ticket, created_at DESC);
CREATE INDEX idx_ticket_logs_id_user ON ticket_logs(id_user);

-- ================================================
-- 9. ROW LEVEL SECURITY
-- ================================================

-- USERS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users viewable by authenticated" ON users
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users update own record" ON users
  FOR UPDATE USING (auth_user_id = auth.uid());
CREATE POLICY "Admins update any user" ON users
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "Users insert own record" ON users
  FOR INSERT WITH CHECK (auth_user_id = auth.uid());

-- HELPDESKS
ALTER TABLE helpdesks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Helpdesks viewable by authenticated" ON helpdesks
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Helpdesks update own record" ON helpdesks
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = helpdesks.id_user AND auth_user_id = auth.uid())
  );
CREATE POLICY "Admins manage helpdesks" ON helpdesks
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin')
  );
CREATE POLICY "Helpdesks insert" ON helpdesks
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin')
  );

-- TICKETS
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Tickets viewable by authenticated" ON tickets
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users create own ticket" ON tickets
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id_user = tickets.id_user AND auth_user_id = auth.uid())
  );
CREATE POLICY "Users update own open ticket" ON tickets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = tickets.id_user AND auth_user_id = auth.uid())
    AND status = 'open'
  );
CREATE POLICY "Helpdesk update assigned ticket" ON tickets
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM helpdesks h
      JOIN users u ON u.id_user = h.id_user
      WHERE h.id_helpdesk = tickets.id_helpdesk
      AND u.auth_user_id = auth.uid()
    )
  );
CREATE POLICY "Admins update any ticket" ON tickets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin')
  );

-- COMMENTS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Comments viewable by authenticated" ON comments
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated add comment" ON comments
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id_user = comments.id_user AND auth_user_id = auth.uid())
  );
CREATE POLICY "Author update own comment" ON comments
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = comments.id_user AND auth_user_id = auth.uid())
  );
CREATE POLICY "Author delete own comment" ON comments
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = comments.id_user AND auth_user_id = auth.uid())
  );

-- TICKET ATTACHMENTS
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ticket attachments viewable" ON ticket_attachments
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Ticket attachments insert" ON ticket_attachments
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Ticket attachments delete" ON ticket_attachments
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM tickets t JOIN users u ON u.id_user = t.id_user
            WHERE t.id_ticket = ticket_attachments.id_ticket AND u.auth_user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM users WHERE auth_user_id = auth.uid() AND role = 'admin')
  );

-- COMMENT ATTACHMENTS
ALTER TABLE comment_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Comment attachments viewable" ON comment_attachments
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Comment attachments insert" ON comment_attachments
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM comments c JOIN users u ON u.id_user = c.id_user
            WHERE c.id_comment = comment_attachments.id_comment AND u.auth_user_id = auth.uid())
  );
CREATE POLICY "Comment attachments delete" ON comment_attachments
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM comments c JOIN users u ON u.id_user = c.id_user
            WHERE c.id_comment = comment_attachments.id_comment AND u.auth_user_id = auth.uid())
  );

-- NOTIFICATIONS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own notifications" ON notifications
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = notifications.id_user AND auth_user_id = auth.uid())
  );
CREATE POLICY "System insert notifications" ON notifications
  FOR INSERT WITH CHECK (auth.role() = 'service_role');
CREATE POLICY "Users update own notifications" ON notifications
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = notifications.id_user AND auth_user_id = auth.uid())
  );
CREATE POLICY "Users delete own notifications" ON notifications
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE id_user = notifications.id_user AND auth_user_id = auth.uid())
  );

-- TICKET LOGS
ALTER TABLE ticket_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Logs viewable by authenticated" ON ticket_logs
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "System insert logs" ON ticket_logs
  FOR INSERT WITH CHECK (auth.role() = 'service_role' OR auth.uid() IS NOT NULL);

-- ================================================
-- 10. TRIGGER: log_ticket_changes
-- ================================================
CREATE OR REPLACE FUNCTION log_ticket_changes()
RETURNS TRIGGER AS $$
DECLARE
  v_event_type TEXT;
  v_payload JSONB;
  v_actor_role user_role;
BEGIN
  BEGIN
    SELECT role INTO v_actor_role FROM users WHERE auth_user_id = auth.uid();
  EXCEPTION WHEN OTHERS THEN
    v_actor_role := 'user';
  END;
  IF v_actor_role IS NULL THEN v_actor_role := 'user'; END IF;

  IF (TG_OP = 'INSERT') THEN
    v_event_type := 'ticket.created';
    v_payload := jsonb_build_object('title', NEW.title, 'description', NEW.description);
  ELSIF (TG_OP = 'UPDATE') THEN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      v_event_type := 'ticket.status_changed';
      v_payload := jsonb_build_object('from', OLD.status::text, 'to', NEW.status::text, 'id_helpdesk', NEW.id_helpdesk);
    ELSIF NEW.id_helpdesk IS DISTINCT FROM OLD.id_helpdesk THEN
      v_event_type := CASE WHEN OLD.id_helpdesk IS NULL THEN 'ticket.assigned' ELSE 'ticket.reassigned' END;
      v_payload := jsonb_build_object('from_hd', OLD.id_helpdesk, 'to_hd', NEW.id_helpdesk);
    ELSIF NEW.photo_path IS DISTINCT FROM OLD.photo_path THEN
      v_event_type := 'ticket.photo_updated';
      v_payload := jsonb_build_object('photo_path', NEW.photo_path);
    ELSIF NEW.cancelled_reason IS DISTINCT FROM OLD.cancelled_reason OR (NEW.status = 'cancelled' AND OLD.status != 'cancelled') THEN
      v_event_type := 'ticket.cancelled';
      v_payload := jsonb_build_object('reason', NEW.cancelled_reason);
    ELSIF NEW.unassign_id_helpdesk IS DISTINCT FROM OLD.unassign_id_helpdesk THEN
      v_event_type := 'ticket.unassign_requested';
      v_payload := jsonb_build_object('requested_by', NEW.unassign_id_helpdesk, 'reason', NEW.unassign_reason);
    ELSIF NEW.unassign_id_user IS DISTINCT FROM OLD.unassign_id_user THEN
      v_event_type := CASE WHEN NEW.status = 'open' THEN 'ticket.unassign_approved' ELSE 'ticket.unassign_rejected' END;
      v_payload := jsonb_build_object('decided_by', NEW.unassign_id_user, 'reject_reason', NEW.unassign_reject_reason);
    ELSE
      v_event_type := 'ticket.updated';
      v_payload := '{}'::jsonb;
    END IF;
  END IF;

  INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload)
  VALUES (NEW.id_ticket, NEW.id_user, v_actor_role, v_event_type, v_payload);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_log_ticket_changes
AFTER INSERT OR UPDATE ON tickets
FOR EACH ROW EXECUTE PROCEDURE log_ticket_changes();

-- ================================================
-- 11. TRIGGER: log_comment_changes
-- ================================================
CREATE OR REPLACE FUNCTION log_comment_changes()
RETURNS TRIGGER AS $$
DECLARE
  v_actor_role user_role;
BEGIN
  SELECT role INTO v_actor_role FROM users WHERE auth_user_id = auth.uid();
  IF v_actor_role IS NULL THEN v_actor_role := 'user'; END IF;

  IF (TG_OP = 'INSERT') THEN
    INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload)
    VALUES (NEW.id_ticket, auth.uid(), v_actor_role, 'comment.added',
            jsonb_build_object('id_comment', NEW.id_comment, 'snippet', left(NEW.message, 100)));
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload)
    VALUES (NEW.id_ticket, auth.uid(), v_actor_role, 'comment.edited',
            jsonb_build_object('id_comment', NEW.id_comment, 'before', OLD.message, 'after', NEW.message));
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload)
    VALUES (OLD.id_ticket, auth.uid(), v_actor_role, 'comment.deleted',
            jsonb_build_object('id_comment', OLD.id_comment, 'message', OLD.message));
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_log_comment_changes
  AFTER INSERT OR UPDATE OR DELETE ON comments
  FOR EACH ROW EXECUTE PROCEDURE log_comment_changes();

-- ================================================
-- 12. TRIGGER: ticket_notifications
-- ================================================
CREATE OR REPLACE FUNCTION create_ticket_notifications()
RETURNS TRIGGER AS $$
BEGIN
  -- INSERT → notify all admin
  IF TG_OP = 'INSERT' THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    SELECT id_user, 'ticket_created', 'Tiket baru',
           'User membuat tiket baru: ' || NEW.title, NEW.id_ticket
    FROM users WHERE role = 'admin';
  END IF;

  -- Assigned → notify user & helpdesk
  IF TG_OP = 'UPDATE' AND NEW.status = 'assigned' AND OLD.status = 'open' THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (NEW.id_user, 'ticket_assigned', 'Tiket di-assign',
            'Tiket Anda telah ditugaskan ke helpdesk.', NEW.id_ticket);
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (
      (SELECT u.id_user FROM helpdesks h JOIN users u ON u.id_user = h.id_user WHERE h.id_helpdesk = NEW.id_helpdesk),
      'ticket_assigned', 'Tiket baru ditugaskan',
      'Admin menugaskan tiket kepada Anda.', NEW.id_ticket
    );
  END IF;

  -- Reassigned → notify old helpdesk, new helpdesk, user
  IF TG_OP = 'UPDATE' AND NEW.id_helpdesk IS DISTINCT FROM OLD.id_helpdesk
     AND NEW.status IN ('assigned', 'in_progress') AND OLD.id_helpdesk IS NOT NULL THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (
      (SELECT u.id_user FROM helpdesks h JOIN users u ON u.id_user = h.id_user WHERE h.id_helpdesk = OLD.id_helpdesk),
      'ticket_unassigned', 'Tiket dilepas',
      'Tiket dilepas dari Anda.', NEW.id_ticket
    );
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (
      (SELECT u.id_user FROM helpdesks h JOIN users u ON u.id_user = h.id_user WHERE h.id_helpdesk = NEW.id_helpdesk),
      'ticket_assigned', 'Tiket ditugaskan ke Anda',
      'Admin menugaskan tiket kepada Anda.', NEW.id_ticket
    );
  END IF;

  -- In progress → notify user
  IF TG_OP = 'UPDATE' AND NEW.status = 'in_progress' AND OLD.status = 'assigned' THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (NEW.id_user, 'ticket_in_progress', 'Tiket sedang dikerjakan',
            'Helpdesk mulai mengerjakan tiket Anda.', NEW.id_ticket);
  END IF;

  -- Done → notify user & all admin
  IF TG_OP = 'UPDATE' AND NEW.status = 'done' AND OLD.status != 'done' THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (NEW.id_user, 'ticket_done', 'Tiket selesai',
            'Tiket Anda telah selesai.', NEW.id_ticket);
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    SELECT id_user, 'ticket_done', 'Tiket selesai',
           'Helpdesk menyelesaikan tiket.', NEW.id_ticket
    FROM users WHERE role = 'admin';
  END IF;

  -- Cancelled → notify all admin
  IF TG_OP = 'UPDATE' AND NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    SELECT id_user, 'ticket_cancelled', 'Tiket dibatalkan',
           'User membatalkan tiket. Alasan: ' || COALESCE(NEW.cancelled_reason, '-'),
           NEW.id_ticket
    FROM users WHERE role = 'admin';
  END IF;

  -- Pending unassign → notify all admin
  IF TG_OP = 'UPDATE' AND NEW.status = 'pending_unassign' AND OLD.status IN ('assigned', 'in_progress') THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    SELECT id_user, 'ticket_unassign_requested', 'Request un-assign',
           'Helpdesk request un-assign. Alasan: ' || COALESCE(NEW.unassign_reason, '-'),
           NEW.id_ticket
    FROM users WHERE role = 'admin';
  END IF;

  -- Unassign approved → notify helpdesk
  IF TG_OP = 'UPDATE' AND NEW.status = 'open' AND OLD.status = 'pending_unassign' AND NEW.unassign_id_user IS NOT NULL THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (
      (SELECT u.id_user FROM helpdesks h JOIN users u ON u.id_user = h.id_user WHERE h.id_helpdesk = NEW.unassign_id_helpdesk),
      'ticket_unassign_approved', 'Un-assign disetujui',
      'Admin menyetujui request un-assign Anda.', NEW.id_ticket
    );
  END IF;

  -- Unassign rejected → notify helpdesk
  IF TG_OP = 'UPDATE' AND NEW.status IN ('assigned', 'in_progress') AND OLD.status = 'pending_unassign' AND NEW.unassign_reject_reason IS NOT NULL THEN
    INSERT INTO notifications (id_user, type, title, body, id_ticket)
    VALUES (
      (SELECT u.id_user FROM helpdesks h JOIN users u ON u.id_user = h.id_user WHERE h.id_helpdesk = NEW.unassign_id_helpdesk),
      'ticket_unassign_rejected', 'Un-assign ditolak',
      'Admin menolak request un-assign Anda.', NEW.id_ticket
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_ticket_notifications
  AFTER INSERT OR UPDATE ON tickets
  FOR EACH ROW EXECUTE PROCEDURE create_ticket_notifications();

-- ================================================
-- 13. TRIGGER: comment_notifications
-- ================================================
CREATE OR REPLACE FUNCTION create_comment_notifications()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (id_user, type, title, body, id_ticket)
  SELECT DISTINCT u.id_user, 'comment_added', 'Komentar baru',
         left(NEW.message, 100), NEW.id_ticket
  FROM tickets t
  CROSS JOIN users u
  WHERE t.id_ticket = NEW.id_ticket
    AND u.id_user != NEW.id_user
    AND u.role != 'admin'
    AND (
      u.id_user = t.id_user
      OR u.id_user = (SELECT h.id_user FROM helpdesks h WHERE h.id_helpdesk = t.id_helpdesk)
    );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_comment_notifications
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE PROCEDURE create_comment_notifications();

-- ================================================
-- 14. TRIGGER: helpdesk_availability_notifications
-- ================================================
CREATE OR REPLACE FUNCTION notify_helpdesk_availability_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_available IS DISTINCT FROM OLD.is_available THEN
    INSERT INTO notifications (id_user, type, title, body)
    SELECT u.id_user, 'helpdesk_availability_changed',
           CASE WHEN NEW.is_available THEN 'Helpdesk Online' ELSE 'Helpdesk Offline',
           CASE WHEN NEW.is_available THEN NEW.name || ' sekarang tersedia' ELSE NEW.name || ' sekarang tidak tersedia' END
    FROM users u
    WHERE u.role = 'user';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_helpdesk_availability_notifications
  AFTER UPDATE ON helpdesks
  FOR EACH ROW EXECUTE PROCEDURE notify_helpdesk_availability_change();

-- ================================================
-- 15. STORAGE BUCKETS (Supabase Storage)
-- ================================================
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('ticket-photos', 'ticket-photos', true),
  ('comment-attachments', 'comment-attachments', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public view ticket photos" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'ticket-photos');

CREATE POLICY "Auth upload ticket photos" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'ticket-photos');

CREATE POLICY "Public view comment attachments" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'comment-attachments');

CREATE POLICY "Auth upload comment attachments" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'comment-attachments');

CREATE POLICY "Public view avatars" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'avatars');

CREATE POLICY "Auth upload own avatar" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ================================================
-- 16. UPDATED_AT TRIGGERS FOR ALL TABLES
-- ================================================

CREATE TRIGGER update_helpdesks_updated_at
  BEFORE UPDATE ON helpdesks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

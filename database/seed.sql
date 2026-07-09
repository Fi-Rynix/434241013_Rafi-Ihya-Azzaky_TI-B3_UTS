-- ================================================
-- E-Ticketing Helpdesk Seed Data
-- Target: Supabase Postgres
-- ================================================

-- ================================================
-- USERS SEED
-- Note: auth_user_id will be NULL for seed data
-- In production, users are auto-created via Supabase Auth trigger
-- ================================================

INSERT INTO users (auth_user_id, username, role, avatar_url, is_active, created_at) VALUES
(NULL, 'admin', 'admin', NULL, true, NOW() - INTERVAL '30 days'),
(NULL, 'helpdesk_alan', 'helpdesk', NULL, true, NOW() - INTERVAL '25 days'),
(NULL, 'helpdesk_viki', 'helpdesk', NULL, true, NOW() - INTERVAL '20 days'),
(NULL, 'helpdesk_siti', 'helpdesk', NULL, false, NOW() - INTERVAL '15 days'),
(NULL, 'john_doe', 'user', NULL, true, NOW() - INTERVAL '10 days'),
(NULL, 'jane_smith', 'user', NULL, true, NOW() - INTERVAL '8 days'),
(NULL, 'bob_wilson', 'user', NULL, true, NOW() - INTERVAL '5 days'),
(NULL, 'alice_chen', 'user', NULL, true, NOW() - INTERVAL '3 days'),
(NULL, 'deactivated_user', 'user', NULL, false, NOW() - INTERVAL '30 days');

-- ================================================
-- HELPDESKS SEED
-- ================================================

INSERT INTO helpdesks (id_user, name, phone, is_available, created_at) VALUES
(2, 'Alan Udin', '+6281234567890', true, NOW() - INTERVAL '25 days'),
(3, 'Viki Bara', '+6281234567891', true, NOW() - INTERVAL '20 days'),
(4, 'Siti Rahayu', '+6281234567892', false, NOW() - INTERVAL '15 days');

-- ================================================
-- TICKETS SEED
-- ================================================

-- Ticket 1: Open (no helpdesk assigned)
INSERT INTO tickets (title, description, status, id_user, created_at) VALUES
('Laptop tidak bisa menyala', 'Laptop Dell Latitude tidak bisa dihidupkan. Sudah dicek charger dan baterai, tetap tidak mau.', 'open', 5, NOW() - INTERVAL '2 days');

-- Ticket 2: Assigned (helpdesk assigned, waiting to start)
INSERT INTO tickets (title, description, status, id_user, id_helpdesk, created_at) VALUES
('Printer tidak mau mencetak', 'Printer HP LaserJet tidak mau mencetak. Lampu indikator berkedip merah terus.', 'assigned', 6, 1, NOW() - INTERVAL '1 day');

-- Ticket 3: In Progress (helpdesk working on it)
INSERT INTO tickets (title, description, status, id_user, id_helpdesk, started_at, created_at) VALUES
('Internet lambat di ruangan meeting', 'Koneksi internet sangat lambat di ruangan meeting lantai 3. Sering disconnect saat video call.', 'in_progress', 7, 2, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '1 day');

-- Ticket 4: Done (completed by helpdesk)
INSERT INTO tickets (title, description, status, id_user, id_helpdesk, started_at, completed_at, created_at) VALUES
('Install Microsoft Office 365', 'Mohon install Microsoft Office 365 di komputer baru lantai 2.', 'done', 8, 1, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days');

-- Ticket 5: Pending Unassign (helpdesk requesting to unassign)
INSERT INTO tickets (title, description, status, id_user, id_helpdesk, unassign_id_helpdesk, unassign_requested_at, unassign_reason, unassign_id_user, created_at) VALUES
('Keyboard beberapa tombol tidak berfungsi', 'Beberapa tombol keyboard tidak berfungsi dengan baik, terutama tombol E, R, dan T.', 'pending_unassign', 5, 3, 3, NOW() - INTERVAL '2 hours', 'Tidak memiliki spare part keyboard tipe ini di gudang', NULL, NOW() - INTERVAL '5 hours');

-- Ticket 6: Cancelled (cancelled by user)
INSERT INTO tickets (title, description, status, id_user, cancelled_at, cancelled_reason, created_at) VALUES
('Request monitor baru 24 inch', 'Mohon diberikan monitor baru 24 inch karena monitor lama bermasalah.', 'cancelled', 6, NOW() - INTERVAL '1 day', 'Sudah tidak jadi, monitor lama masih bisa dipakai', NOW() - INTERVAL '2 days');

-- ================================================
-- TICKET ATTACHMENTS SEED
-- ================================================

INSERT INTO ticket_attachments (id_ticket, storage_path, mime_type, file_size, uploaded_at) VALUES
(1, 'ticket-photos/ticket_1/laptop_photo.jpg', 'image/jpeg', 245000, NOW() - INTERVAL '2 days'),
(4, 'ticket-photos/ticket_4/office_screenshot.png', 'image/png', 128000, NOW() - INTERVAL '2 days');

-- ================================================
-- COMMENTS SEED
-- ================================================

-- Comments for Ticket 1 (open)
INSERT INTO comments (id_ticket, id_user, message, is_edited, created_at) VALUES
(1, 2, 'Terima kasih atas laporan-nya. Tim kami akan segera memproses tiket ini.', false, NOW() - INTERVAL '1 day 20 hours'),
(1, 5, 'Baik, saya tunggu kabar selanjutnya. Terima kasih.', false, NOW() - INTERVAL '1 day 18 hours);

-- Comments for Ticket 2 (assigned)
INSERT INTO comments (id_ticket, id_user, message, is_edited, created_at) VALUES
(2, 2, 'Sudah saya cek, kemungkinan toner habis. Akan saya ganti besok pagi.', false, NOW() - INTERVAL '20 hours'),
(2, 6, 'Baik terima kasih mas Alan. Ditunggu ya.', false, NOW() - INTERVAL '18 hours);

-- Comments for Ticket 3 (in_progress)
INSERT INTO comments (id_ticket, id_user, message, is_edited, created_at) VALUES
(3, 3, 'Sudah dilakukan pengecekan. Masalah di access point lantai 3, perlu diganti.', false, NOW() - INTERVAL '10 hours'),
(3, 3, 'Access point sudah diganti. Mohon dicoba lagi koneksi internet-nya.', false, NOW() - INTERVAL '2 hours'),
(3, 7, 'Sudah coba, masih kadang-kadang putus. Bisa dicek lagi?', false, NOW() - INTERVAL '1 hour');

-- Comments for Ticket 4 (done)
INSERT INTO comments (id_ticket, id_user, message, is_edited, created_at) VALUES
(4, 2, 'Software Office 365 sudah terinstall dan aktivasi berhasil. Silakan dicek.', false, NOW() - INTERVAL '1 day 12 hours'),
(4, 8, 'Sudahdicek, berfungsi dengan baik. Terima kasih banyak!', false, NOW() - INTERVAL '1 day);

-- Comments for Ticket 5 (pending_unassign)
INSERT INTO comments (id_ticket, id_user, message, is_edited, created_at) VALUES
(5, 4, 'Mohon maaf, keyboard tipe ini sudah tidak ada stok di gudang. Mohon untuk di-unassign agar bisa dialihkan ke helpdesk lain yang mungkin punya stok.', false, NOW() - INTERVAL '2 hours);

-- Comments for Ticket 6 (cancelled)
INSERT INTO comments (id_ticket, id_user, message, is_edited, created_at) VALUES
(6, 1, 'Mohon maaf, monitor 24 inch tidak bisa diproses bulan ini karena keterbatasan budget. Mohon ditutup atau dibuat tiket baru jika urgent.', false, NOW() - INTERVAL '1 day 12 hours');

-- ================================================
-- COMMENT ATTACHMENTS SEED
-- ================================================

INSERT INTO comment_attachments (id_comment, storage_path, mime_type, file_size, uploaded_at) VALUES
(3, 'comment-attachments/comment_3/screenshot_error.png', 'image/png', 512000, NOW() - INTERVAL '10 hours'),
(5, 'comment-attachments/comment_5/invoice_office.jpg', 'image/jpeg', 340000, NOW() - INTERVAL '1 day 12 hours');

-- ================================================
-- NOTIFICATIONS SEED
-- ================================================

-- Notifications for user 5 (john_doe)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(5, 'ticket_created', 'Tiket Dibuat', 'Tiket #1 berhasil dibuat: Laptop tidak bisa menyala', 1, true, NOW() - INTERVAL '2 days'),
(5, 'ticket_created', 'Tiket Dibuat', 'Tiket #5 berhasil dibuat: Keyboard beberapa tombol tidak berfungsi', 5, true, NOW() - INTERVAL '5 hours'),
(5, 'ticket_unassign_requested', 'Request Un-assign', 'Helpdesk Siti Rahayu meminta un-assign tiket #5', 5, false, NOW() - INTERVAL '2 hours');

-- Notifications for user 6 (jane_smith)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(6, 'ticket_created', 'Tiket Dibuat', 'Tiket #2 berhasil dibuat: Printer tidak mau mencetak', 2, true, NOW() - INTERVAL '1 day'),
(6, 'ticket_assigned', 'Tiket Ditugaskan', 'Tiket #2 telah ditugaskan ke helpdesk Alan Udin', 2, true, NOW() - INTERVAL '23 hours'),
(6, 'ticket_cancelled', 'Tiket Dibatalkan', 'Tiket #6 telah dibatalkan', 6, true, NOW() - INTERVAL '1 day),
(6, 'ticket_created', 'Tiket Dibuat', 'Tiket #6 berhasil dibuat: Request monitor baru 24 inch', 6, true, NOW() - INTERVAL '2 days');

-- Notifications for user 7 (bob_wilson)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(7, 'ticket_created', 'Tiket Dibuat', 'Tiket #3 berhasil dibuat: Internet lambat di ruangan meeting', 3, true, NOW() - INTERVAL '1 day'),
(7, 'ticket_assigned', 'Tiket Ditugaskan', 'Tiket #3 telah ditugaskan ke helpdesk Viki Bara', 3, true, NOW() - INTERVAL '20 hours'),
(7, 'ticket_in_progress', 'Sedang Dikerjakan', 'Helpdesk sedang mengerjakan tiket #3', 3, true, NOW() - INTERVAL '12 hours);

-- Notifications for user 8 (alice_chen)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(8, 'ticket_created', 'Tiket Dibuat', 'Tiket #4 berhasil dibuat: Install Microsoft Office 365', 4, true, NOW() - INTERVAL '3 days'),
(8, 'ticket_assigned', 'Tiket Ditugaskan', 'Tiket #4 telah ditugaskan ke helpdesk Alan Udin', 4, true, NOW() - INTERVAL '2 days 12 hours'),
(8, 'ticket_done', 'Tiket Selesai', 'Tiket #4 telah selesai dikerjakan', 4, true, NOW() - INTERVAL '1 day);

-- Notifications for helpdesk 1 (Alan Udin)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(2, 'ticket_assigned', 'Tiket Baru Ditugaskan', 'Admin menugaskan tiket baru kepada Anda: Printer tidak mau mencetak', 2, true, NOW() - INTERVAL '23 hours'),
(2, 'ticket_assigned', 'Tiket Baru Ditugaskan', 'Admin menugaskan tiket baru kepada Anda: Install Microsoft Office 365', 4, true, NOW() - INTERVAL '2 days 12 hours');

-- Notifications for helpdesk 2 (Viki Bara)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(3, 'ticket_assigned', 'Tiket Baru Ditugaskan', 'Admin menugaskan tiket baru kepada Anda: Internet lambat di ruangan meeting', 3, true, NOW() - INTERVAL '20 hours);

-- Notifications for helpdesk 3 (Siti Rahayu)
INSERT INTO notifications (id_user, type, title, body, id_ticket, is_read, created_at) VALUES
(4, 'ticket_assigned', 'Tiket Baru Ditugaskan', 'Admin menugaskan tiket baru kepada Anda: Keyboard beberapa tombol tidak berfungsi', 5, true, NOW() - INTERVAL '5 hours),
(4, 'ticket_unassign_requested', 'Request Un-assign', 'Anda meminta un-assign tiket #5', 5, false, NOW() - INTERVAL '2 hours);

-- ================================================
-- TICKET LOGS SEED
-- ================================================

-- Ticket 1 logs
INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload, created_at) VALUES
(1, 5, 'user', 'ticket.created', '{"title": "Laptop tidak bisa menyala"}', NOW() - INTERVAL '2 days'),
(1, 2, 'helpdesk', 'ticket.viewed', '{"viewed_by": "Alan Udin"}', NOW() - INTERVAL '1 day 22 hours),
(1, 2, 'helpdesk', 'comment.added', '{"id_comment": 1, "snippet": "Terima kasih atas laporan-nya"}', NOW() - INTERVAL '1 day 20 hours),
(1, 5, 'user', 'comment.added', '{"id_comment": 2, "snippet": "Baik, saya tunggu"}', NOW() - INTERVAL '1 day 18 hours);

-- Ticket 2 logs
INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload, created_at) VALUES
(2, 6, 'user', 'ticket.created', '{"title": "Printer tidak mau mencetak"}', NOW() - INTERVAL '1 day'),
(2, 1, 'admin', 'ticket.assigned', '{"to_hd": 1, "helpdesk_name": "Alan Udin"}', NOW() - INTERVAL '23 hours'),
(2, 2, 'helpdesk', 'comment.added', '{"id_comment": 3, "snippet": "Sudah saya cek, kemungkinan toner"}', NOW() - INTERVAL '20 hours),
(2, 6, 'user', 'comment.added', '{"id_comment": 4, "snippet": "Baik terima kasih"}', NOW() - INTERVAL '18 hours);

-- Ticket 3 logs
INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload, created_at) VALUES
(3, 7, 'user', 'ticket.created', '{"title": "Internet lambat di ruangan meeting"}', NOW() - INTERVAL '1 day'),
(3, 1, 'admin', 'ticket.assigned', '{"to_hd": 2, "helpdesk_name": "Viki Bara"}', NOW() - INTERVAL '20 hours),
(3, 2, 'helpdesk', 'ticket.status_changed', '{"from": "assigned", "to": "in_progress", "id_helpdesk": 2}', NOW() - INTERVAL '12 hours),
(3, 3, 'helpdesk', 'comment.added', '{"id_comment": 5, "snippet": "Sudah dilakukan pengecekan"}', NOW() - INTERVAL '10 hours),
(3, 3, 'helpdesk', 'comment.added', '{"id_comment": 6, "snippet": "Access point sudah diganti"}', NOW() - INTERVAL '2 hours),
(3, 7, 'user', 'comment.added', '{"id_comment": 7, "snippet": "Sudah coba, masih kadang-kadang"}', NOW() - INTERVAL '1 hour);

-- Ticket 4 logs
INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload, created_at) VALUES
(4, 8, 'user', 'ticket.created', '{"title": "Install Microsoft Office 365"}', NOW() - INTERVAL '3 days'),
(4, 1, 'admin', 'ticket.assigned', '{"to_hd": 1, "helpdesk_name": "Alan Udin"}', NOW() - INTERVAL '2 days 12 hours),
(4, 2, 'helpdesk', 'ticket.status_changed', '{"from": "assigned", "to": "in_progress", "id_helpdesk": 1}', NOW() - INTERVAL '2 days),
(4, 2, 'helpdesk', 'comment.added', '{"id_comment": 8, "snippet": "Software Office 365 sudah"}', NOW() - INTERVAL '1 day 12 hours),
(4, 2, 'helpdesk', 'ticket.status_changed', '{"from": "in_progress", "to": "done", "id_helpdesk": 1}', NOW() - INTERVAL '1 day),
(4, 8, 'user', 'comment.added', '{"id_comment": 9, "snippet": "Sudah dicek, berfungsi"}', NOW() - INTERVAL '1 day);

-- Ticket 5 logs
INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload, created_at) VALUES
(5, 5, 'user', 'ticket.created', '{"title": "Keyboard beberapa tombol tidak berfungsi"}', NOW() - INTERVAL '5 hours'),
(5, 1, 'admin', 'ticket.assigned', '{"to_hd": 3, "helpdesk_name": "Siti Rahayu"}', NOW() - INTERVAL '5 hours),
(5, 4, 'helpdesk', 'ticket.unassign_requested', '{"requested_by": 3, "reason": "Tidak memiliki spare part keyboard tipe ini di gudang"}', NOW() - INTERVAL '2 hours),
(5, 4, 'helpdesk', 'comment.added', '{"id_comment": 10, "snippet": "Mohon maaf, keyboard tipe ini"}', NOW() - INTERVAL '2 hours);

-- Ticket 6 logs
INSERT INTO ticket_logs (id_ticket, id_user, actor_role, event_type, payload, created_at) VALUES
(6, 6, 'user', 'ticket.created', '{"title": "Request monitor baru 24 inch"}', NOW() - INTERVAL '2 days'),
(6, 1, 'admin', 'ticket.cancelled', '{"reason": "Budget tidak tersedia bulan ini"}', NOW() - INTERVAL '1 day 12 hours),
(6, 1, 'admin', 'comment.added', '{"id_comment": 11, "snippet": "Mohon maaf, monitor 24 inch"}', NOW() - INTERVAL '1 day 12 hours);

-- ================================================
-- SUMMARY QUERIES
-- ================================================

SELECT 'Seed completed!' AS status;

-- Counts
SELECT 'Users: ' || COUNT(*)::text AS count FROM users;
SELECT 'Helpdesks: ' || COUNT(*)::text AS count FROM helpdesks;
SELECT 'Tickets: ' || COUNT(*)::text AS count FROM tickets;
SELECT 'Ticket Attachments: ' || COUNT(*)::text AS count FROM ticket_attachments;
SELECT 'Comments: ' || COUNT(*)::text AS count FROM comments;
SELECT 'Comment Attachments: ' || COUNT(*)::text AS count FROM comment_attachments;
SELECT 'Notifications: ' || COUNT(*)::text AS count FROM notifications;
SELECT 'Ticket Logs: ' || COUNT(*)::text AS count FROM ticket_logs;

-- Ticket status breakdown
SELECT status, COUNT(*) AS count FROM tickets GROUP BY status ORDER BY status;

-- Unread notifications
SELECT u.username, COUNT(n.id_notification) AS unread
FROM notifications n
JOIN users u ON u.id_user = n.id_user
WHERE n.is_read = false
GROUP BY u.username
ORDER BY unread DESC;

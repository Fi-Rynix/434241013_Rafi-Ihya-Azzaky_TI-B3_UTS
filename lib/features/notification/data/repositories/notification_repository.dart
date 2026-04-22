import '../models/notification_model.dart';

class NotificationRepository {
  // Dummy notifications data
  static final List<Notification> _notifications = [
    Notification(
      id: 'notif_001',
      title: 'Tiket Anda Telah Diassign',
      description: 'Teknisi Alan Udin telah diassign ke tiket Anda',
      time: '2 hours ago',
      relatedTicketId: 'ticket_001',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    Notification(
      id: 'notif_002',
      title: 'Status Tiket Diperbarui',
      description: 'Tiket masalah printer Anda sekarang dalam Status Proses',
      time: '4 hours ago',
      relatedTicketId: 'ticket_002',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
    ),
    Notification(
      id: 'notif_003',
      title: 'Konfirmasi Tiket Baru',
      description: 'Tiket masalah jaringan Anda telah diterima',
      time: '1 day ago',
      relatedTicketId: 'ticket_003',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    Notification(
      id: 'notif_004',
      title: 'Tiket Selesai',
      description: 'Masalah monitor Anda telah diselesaikan',
      time: '2 days ago',
      relatedTicketId: 'ticket_004',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    Notification(
      id: 'notif_005',
      title: 'Komentar Ditambahkan',
      description: 'Teknisi Vikibara Can menambahkan komentar ke tiket Anda',
      time: '3 days ago',
      relatedTicketId: 'ticket_005',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  /// Get all notifications
  Future<List<Notification>> getAllNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications;
  }

  /// Get unread notifications only
  Future<List<Notification>> getUnreadNotifications() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get notification by id
  Future<Notification?> getNotificationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Mark notification as read
  Future<Notification?> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        return _notifications[index];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _notifications.where((n) => !n.isRead).length;
  }
}

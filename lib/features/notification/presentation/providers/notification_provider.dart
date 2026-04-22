import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

// Provider untuk get semua notifikasi
final allNotificationsProvider = FutureProvider((ref) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return await notificationRepo.getAllNotifications();
});

// Provider untuk get notifikasi yang belum dibaca
final unreadNotificationsProvider = FutureProvider((ref) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return await notificationRepo.getUnreadNotifications();
});

// Provider untuk count notifikasi yang belum dibaca
final unreadCountProvider = FutureProvider((ref) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return await notificationRepo.getUnreadCount();
});

// Provider untuk get detail notifikasi
final notificationDetailProvider = FutureProvider.family<Notification?, String>((ref, notificationId) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  return await notificationRepo.getNotificationById(notificationId);
});

// Provider untuk mark notification as read
final markNotificationAsReadProvider = FutureProvider.family<Notification?, String>((ref, notificationId) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final result = await notificationRepo.markAsRead(notificationId);
  // Refresh providers setelah mark as read
  ref.refresh(allNotificationsProvider);
  ref.refresh(unreadNotificationsProvider);
  ref.refresh(unreadCountProvider);
  return result;
});

// Provider untuk mark all as read
final markAllAsReadProvider = FutureProvider((ref) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  await notificationRepo.markAllAsRead();
  // Refresh providers
  ref.refresh(allNotificationsProvider);
  ref.refresh(unreadNotificationsProvider);
  ref.refresh(unreadCountProvider);
});

// Provider untuk delete notification
final deleteNotificationProvider = FutureProvider.family<bool, String>((ref, notificationId) async {
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  final result = await notificationRepo.deleteNotification(notificationId);
  // Refresh providers setelah delete
  ref.refresh(allNotificationsProvider);
  ref.refresh(unreadNotificationsProvider);
  ref.refresh(unreadCountProvider);
  return result;
});

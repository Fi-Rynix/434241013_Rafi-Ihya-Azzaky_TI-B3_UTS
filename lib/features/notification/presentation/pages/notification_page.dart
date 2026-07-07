import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ticket/presentation/pages/ticket_detail_page.dart';
import '../../../ticket/presentation/providers/ticket_pagination.dart';
import '../providers/notification_provider.dart';
import '../providers/notification_pagination_provider.dart';
import '../../data/models/notification_model.dart';
import '../../../../shared/widgets/load_more_button.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedNotificationsProvider.notifier).loadFirstPage();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final paginationState = ref.watch(paginatedNotificationsProvider);

    if (currentUser == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return Column(
      children: [
        // Compact navy header with filter buttons + mark all read
        Container(
          color: AppTheme.accentColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FilterButton(
                      label: 'Semua',
                      isSelected: _tabController.index == 0,
                      onTap: () => setState(() => _tabController.animateTo(0)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterButton(
                      label: 'Belum Dibaca',
                      isSelected: _tabController.index == 1,
                      onTap: () => setState(() => _tabController.animateTo(1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _markAllAsRead(currentUser.idUser),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Tandai semua sudah dibaca'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllTab(paginationState),
              _buildUnreadTab(paginationState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllTab(PaginationState<Notification> state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(paginatedNotificationsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return _emptyState(message: 'Tidak ada notifikasi');
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(paginatedNotificationsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return LoadMoreButton(
              isLoading: state.isLoading,
              hasMore: state.hasMore,
              onPressed: () => ref.read(paginatedNotificationsProvider.notifier).loadMore(),
              currentCount: state.items.length,
            );
          }
          return _NotificationCard(
            notification: state.items[index],
            onTap: () => _handleNotificationTap(state.items[index]),
          );
        },
      ),
    );
  }

  Widget _buildUnreadTab(PaginationState<Notification> state) {
    final unread = state.items.where((n) => !n.isRead).toList();

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (unread.isEmpty) {
      return _emptyState(message: 'Tidak ada notifikasi belum dibaca');
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(paginatedNotificationsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: unread.length,
        itemBuilder: (context, index) {
          return _NotificationCard(
            notification: unread[index],
            onTap: () => _handleNotificationTap(unread[index]),
          );
        },
      ),
    );
  }

  Widget _emptyState({String message = 'No notifications'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppTheme.textMuted(context)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppTheme.textSubtle(context))),
        ],
      ),
    );
  }

  void _handleNotificationTap(Notification notification) async {
    if (!notification.isRead) {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(notification.idNotification);
      ref.invalidate(paginatedNotificationsProvider);
      ref.invalidate(userNotificationsProvider(ref.read(currentUserProvider)!.idUser));
    }

    if (notification.idTicket != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TicketDetailPage(ticketId: notification.idTicket!),
        ),
      );
      ref.invalidate(paginatedNotificationsProvider);
    }
  }

  void _markAllAsRead(int idUser) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead(idUser);
    ref.invalidate(paginatedNotificationsProvider);
    ref.invalidate(userNotificationsProvider(idUser));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.iconBg(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIcon(notification.type),
            color: isUnread ? AppTheme.accentColor : AppTheme.textMuted(context),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
            color: isUnread ? AppTheme.primaryText(context) : AppTheme.textSubtle(context),
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSubtle(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF000072),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ticket_created':
        return Icons.add_circle_outline;
      case 'ticket_assigned':
        return Icons.person_outline;
      case 'ticket_reassigned':
        return Icons.swap_horiz;
      case 'ticket_unassigned':
        return Icons.person_remove_outlined;
      case 'ticket_unassign_requested':
        return Icons.exit_to_app;
      case 'ticket_unassign_approved':
        return Icons.check_circle_outline;
      case 'ticket_unassign_rejected':
        return Icons.cancel_outlined;
      case 'ticket_in_progress':
        return Icons.play_circle_outline;
      case 'ticket_done':
        return Icons.check_circle_outline;
      case 'ticket_cancelled':
        return Icons.cancel_outlined;
      case 'ticket_edited':
        return Icons.edit_outlined;
      case 'comment_added':
        return Icons.chat_bubble_outline;
      case 'helpdesk_availability_changed':
        return Icons.event_available_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentColor : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
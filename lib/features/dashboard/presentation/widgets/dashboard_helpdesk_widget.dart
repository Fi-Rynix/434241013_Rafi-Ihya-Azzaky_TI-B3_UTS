import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../ticket/presentation/providers/ticket_provider.dart';
import '../../../ticket/presentation/providers/helpdesk_provider.dart';
import '../../data/models/dashboard_model.dart';

class DashboardHelpdeskWidget extends ConsumerWidget {
  const DashboardHelpdeskWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final helpdeskAsync = ref.watch(helpdeskByUserProvider(currentUser?.idUser ?? 0));
    final ticketsAsync = ref.watch(fetchAllTicketsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(fetchAllTicketsProvider);
        ref.invalidate(helpdeskByUserProvider(currentUser?.idUser ?? 0));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Text(
              'Welcome back,',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.textSubtle(context)),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser?.username ?? 'Helpdesk',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppTheme.primaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.iconBg(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.accentColor,
                  width: 1.2,
                ),
              ),
              child: Text(
                'HELPDESK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppTheme.iconStroke(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Here's your ticket overview",
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 32),

            // Toggle availability
            helpdeskAsync.when(
              data: (helpdesk) {
                if (helpdesk == null) return const SizedBox();
                return _AvailabilityCard(
                  isAvailable: helpdesk.isAvailable,
                  onTap: () async {
                    final repo = ref.read(helpdeskRepositoryProvider);
                    await repo.toggleAvailability(
                      idHelpdesk: helpdesk.idHelpdesk,
                      isAvailable: !helpdesk.isAvailable,
                    );
                    ref.invalidate(helpdeskByUserProvider(currentUser?.idUser ?? 0));
                  },
                );
              },
              loading: () => const SizedBox(height: 70),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // Stats (same style as User dashboard — no color variations)
            ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
              data: (allTickets) {
                final helpdesk = helpdeskAsync.valueOrNull;
                if (helpdesk == null) return const SizedBox();

                final assignedTickets = allTickets.where((t) => t.idHelpdesk == helpdesk.idHelpdesk).toList();
                final assigned = assignedTickets.where((t) => t.status.value == 'assigned').length;
                final inProgress = assignedTickets.where((t) => t.status.value == 'in_progress').length;
                final pending = assignedTickets.where((t) => t.status.value == 'pending_unassign').length;
                final done = assignedTickets.where((t) => t.status.value == 'done').length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Assigned',
                            value: assigned.toString(),
                            icon: Icons.assignment_ind_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'In Progress',
                            value: inProgress.toString(),
                            icon: Icons.pending_actions_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Pending',
                            value: pending.toString(),
                            icon: Icons.hourglass_empty_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Done',
                            value: done.toString(),
                            icon: Icons.task_alt_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.iconBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.iconStroke(context), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onTap;

  const _AvailabilityCard({required this.isAvailable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerSubtle(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.iconBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle_outline : Icons.pause_circle_outlined,
                  color: AppTheme.iconStroke(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAvailable ? 'You are Available' : 'You are Unavailable',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to toggle status',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.swap_horiz, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
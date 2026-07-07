import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/dashboard_model.dart';

class DashboardAdminWidget extends ConsumerWidget {
  const DashboardAdminWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final dashboardStatsAsync = ref.watch(adminDashboardStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(adminDashboardStatsProvider, (previous, next) {});

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardStatsProvider);
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSubtle(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentUser?.username ?? 'Admin',
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
                'ADMIN',
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

            // Stats section
            dashboardStatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Column(
                children: [
                  Text('Error: $error', style: TextStyle(color: Colors.red[400])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(adminDashboardStatsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (DashboardStats stats) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Big accent card
                    _StatCard(
                      title: 'Total Tickets',
                      value: stats.totalTickets.toString(),
                      icon: Icons.confirmation_number_outlined,
                      isAccent: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Open',
                            value: stats.openTickets.toString(),
                            icon: Icons.circle_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Assigned',
                            value: stats.assignedTickets.toString(),
                            icon: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'In Progress',
                            value: stats.inProgressTickets.toString(),
                            icon: Icons.pending_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Done',
                            value: stats.doneTickets.toString(),
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Cancelled',
                            value: stats.cancelledTickets.toString(),
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Active',
                            value: stats.activeTickets.toString(),
                            icon: Icons.access_time_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Action card: User Management
                    _ActionCard(
                      title: 'Kelola Pengguna',
                      subtitle: 'Manage users, roles, & status',
                      icon: Icons.people_alt_outlined,
                      onTap: () => Navigator.of(context).pushNamed(AppConstants.routeUserManagement),
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
  final bool isAccent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isAccent = false,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isAccent ? AppTheme.accentColor : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isAccent
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.iconBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isAccent ? Colors.white : AppTheme.iconStroke(context),
                  size: 18,
                ),
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
                        fontSize: isAccent ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: isAccent
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black),
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
                          color: isAccent
                              ? Colors.white70
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.iconBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.iconStroke(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
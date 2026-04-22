import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

// Provider untuk user dashboard stats
final userDashboardStatsProvider = FutureProvider.family<DashboardStats, String>((ref, username) async {
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  return await dashboardRepo.getUserDashboardStats(username);
});

// Provider untuk admin dashboard stats
final adminDashboardStatsProvider = FutureProvider((ref) async {
  final dashboardRepo = ref.watch(dashboardRepositoryProvider);
  return await dashboardRepo.getAdminDashboardStats();
});

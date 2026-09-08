import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_dashboard_repository.dart';
import '../data/models/admin_dashboard_stats.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(apiClient: ref.watch(apiClientProvider));
});

final adminDashboardStatsProvider = FutureProvider.autoDispose<AdminDashboardStats>((ref) {
  return ref.read(adminDashboardRepositoryProvider).stats();
});

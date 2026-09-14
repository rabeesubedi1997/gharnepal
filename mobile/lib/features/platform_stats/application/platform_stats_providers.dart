import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/platform_stats.dart';
import '../data/platform_stats_repository.dart';

final platformStatsRepositoryProvider = Provider<PlatformStatsRepository>((ref) {
  return PlatformStatsRepository(apiClient: ref.watch(apiClientProvider));
});

final platformStatsProvider = FutureProvider.autoDispose<PlatformStats>((ref) {
  return ref.watch(platformStatsRepositoryProvider).fetch();
});

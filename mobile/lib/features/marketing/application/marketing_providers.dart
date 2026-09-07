import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/banner.dart';
import '../data/marketing_repository.dart';

final marketingRepositoryProvider = Provider<MarketingRepository>((ref) {
  return MarketingRepository(apiClient: ref.watch(apiClientProvider));
});

final bannersProvider = FutureProvider<List<AppBanner>>((ref) {
  return ref.read(marketingRepositoryProvider).banners();
});

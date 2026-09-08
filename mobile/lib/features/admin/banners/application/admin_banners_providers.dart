import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_banners_repository.dart';
import '../data/models/admin_banner.dart';

final adminBannersRepositoryProvider = Provider<AdminBannersRepository>((ref) {
  return AdminBannersRepository(apiClient: ref.watch(apiClientProvider));
});

final adminBannersListProvider = FutureProvider.autoDispose<List<AdminBanner>>((ref) {
  return ref.watch(adminBannersRepositoryProvider).list();
});

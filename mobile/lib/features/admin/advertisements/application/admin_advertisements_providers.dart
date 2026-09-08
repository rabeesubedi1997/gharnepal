import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_advertisements_repository.dart';
import '../data/models/admin_advertisement.dart';

final adminAdvertisementsRepositoryProvider = Provider<AdminAdvertisementsRepository>((ref) {
  return AdminAdvertisementsRepository(apiClient: ref.watch(apiClientProvider));
});

final adminAdvertisementsListProvider = FutureProvider.autoDispose<List<AdminAdvertisement>>((ref) {
  return ref.watch(adminAdvertisementsRepositoryProvider).list();
});

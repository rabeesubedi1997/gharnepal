import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_amenities_repository.dart';
import '../data/models/admin_amenity.dart';

final adminAmenitiesRepositoryProvider = Provider<AdminAmenitiesRepository>((ref) {
  return AdminAmenitiesRepository(apiClient: ref.watch(apiClientProvider));
});

final adminAmenitiesListProvider = FutureProvider.autoDispose<List<AdminAmenity>>((ref) {
  return ref.watch(adminAmenitiesRepositoryProvider).list();
});

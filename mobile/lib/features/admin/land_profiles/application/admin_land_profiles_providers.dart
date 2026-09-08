import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../listings/data/models/land_profile.dart';
import '../data/admin_land_profiles_repository.dart';

final adminLandProfilesRepositoryProvider = Provider<AdminLandProfilesRepository>((ref) {
  return AdminLandProfilesRepository(apiClient: ref.watch(apiClientProvider));
});

final adminLandProfileProvider = FutureProvider.autoDispose.family<LandProfile, int>((ref, propertyId) {
  return ref.read(adminLandProfilesRepositoryProvider).get(propertyId);
});

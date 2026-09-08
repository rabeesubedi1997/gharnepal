import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/district.dart';
import '../data/locations_repository.dart';
import '../data/municipality.dart';
import '../data/neighborhood.dart';
import '../data/province.dart';
import '../data/ward.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(apiClient: ref.watch(apiClientProvider));
});

final municipalitiesProvider = FutureProvider<List<Municipality>>((ref) {
  return ref.read(locationsRepositoryProvider).municipalities();
});

/// The address cascade used by the Post-Property Wizard's Location step:
/// province -> district -> municipality -> ward -> neighborhood, each level
/// re-fetched only once its parent is picked.
final provincesProvider = FutureProvider<List<Province>>((ref) {
  return ref.read(locationsRepositoryProvider).provinces();
});

final districtsProvider = FutureProvider.family<List<District>, int>((ref, provinceId) {
  return ref.read(locationsRepositoryProvider).districts(provinceId: provinceId);
});

final municipalitiesForDistrictProvider = FutureProvider.family<List<Municipality>, int>((ref, districtId) {
  return ref.read(locationsRepositoryProvider).municipalities(districtId: districtId);
});

final wardsProvider = FutureProvider.family<List<Ward>, int>((ref, municipalityId) {
  return ref.read(locationsRepositoryProvider).wards(municipalityId: municipalityId);
});

final neighborhoodsProvider = FutureProvider.family<List<Neighborhood>, int>((ref, wardId) {
  return ref.read(locationsRepositoryProvider).neighborhoods(wardId: wardId);
});

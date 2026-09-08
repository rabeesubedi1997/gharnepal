import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_locations_repository.dart';
import '../data/models/district.dart';
import '../data/models/municipality.dart';
import '../data/models/neighborhood.dart';
import '../data/models/province.dart';
import '../data/models/ward.dart';

final adminLocationsRepositoryProvider = Provider<AdminLocationsRepository>((ref) {
  return AdminLocationsRepository(apiClient: ref.watch(apiClientProvider));
});

final adminProvincesProvider = FutureProvider.autoDispose<List<Province>>((ref) {
  return ref.read(adminLocationsRepositoryProvider).provinces();
});

/// Empty (no network call) until a province is chosen — mirrors the
/// cascading-select UI requirement.
final adminDistrictsProvider = FutureProvider.autoDispose.family<List<District>, int?>((ref, provinceId) {
  if (provinceId == null) return Future.value(const []);
  return ref.read(adminLocationsRepositoryProvider).districts(provinceId: provinceId);
});

/// Unlike the other cascading levels, a `null` districtId still hits the
/// network — the backend returns ALL municipalities unfiltered.
final adminMunicipalitiesProvider = FutureProvider.autoDispose.family<List<Municipality>, int?>((
  ref,
  districtId,
) {
  return ref.read(adminLocationsRepositoryProvider).municipalities(districtId: districtId);
});

final adminWardsProvider = FutureProvider.autoDispose.family<List<Ward>, int?>((ref, municipalityId) {
  if (municipalityId == null) return Future.value(const []);
  return ref.read(adminLocationsRepositoryProvider).wards(municipalityId: municipalityId);
});

final adminNeighborhoodsProvider = FutureProvider.autoDispose.family<List<Neighborhood>, int?>((ref, wardId) {
  if (wardId == null) return Future.value(const []);
  return ref.read(adminLocationsRepositoryProvider).neighborhoods(wardId: wardId);
});

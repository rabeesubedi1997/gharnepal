import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/locations_repository.dart';
import '../data/municipality.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(apiClient: ref.watch(apiClientProvider));
});

final municipalitiesProvider = FutureProvider<List<Municipality>>((ref) {
  return ref.read(locationsRepositoryProvider).municipalities();
});

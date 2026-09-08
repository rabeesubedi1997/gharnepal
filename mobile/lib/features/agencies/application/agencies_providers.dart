import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/agencies_repository.dart';
import '../data/models/agency_profile.dart';
import '../data/models/agency_summary.dart';

final agenciesRepositoryProvider = Provider<AgenciesRepository>((ref) {
  return AgenciesRepository(apiClient: ref.watch(apiClientProvider));
});

final agenciesListProvider = FutureProvider.autoDispose<List<AgencySummary>>((ref) {
  return ref.read(agenciesRepositoryProvider).list();
});

final agencyProfileProvider = FutureProvider.autoDispose.family<AgencyProfile, String>((ref, slug) {
  return ref.read(agenciesRepositoryProvider).detail(slug);
});

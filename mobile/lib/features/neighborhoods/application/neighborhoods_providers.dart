import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/neighborhood_profile.dart';
import '../data/models/neighborhood_summary.dart';
import '../data/neighborhoods_repository.dart';

final neighborhoodsRepositoryProvider = Provider<NeighborhoodsRepository>((ref) {
  return NeighborhoodsRepository(apiClient: ref.watch(apiClientProvider));
});

final neighborhoodsListProvider = FutureProvider.autoDispose<List<NeighborhoodSummary>>((ref) {
  return ref.read(neighborhoodsRepositoryProvider).list();
});

final neighborhoodProfileProvider = FutureProvider.autoDispose.family<NeighborhoodProfile, int>((ref, id) {
  return ref.read(neighborhoodsRepositoryProvider).detail(id);
});

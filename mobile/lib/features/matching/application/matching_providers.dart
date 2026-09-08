import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/matching_repository.dart';
import '../data/models/match_preference.dart';
import '../data/models/match_result.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepository(apiClient: ref.watch(apiClientProvider));
});

final matchPreferencesProvider = FutureProvider.autoDispose<MatchPreference>((ref) {
  return ref.read(matchingRepositoryProvider).getPreferences();
});

final matchResultsProvider = FutureProvider.autoDispose<List<MatchResult>>((ref) {
  return ref.read(matchingRepositoryProvider).getResults();
});

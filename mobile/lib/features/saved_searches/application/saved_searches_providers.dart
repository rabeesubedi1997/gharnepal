import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/saved_search.dart';
import '../data/saved_searches_repository.dart';

final savedSearchesRepositoryProvider = Provider<SavedSearchesRepository>((ref) {
  return SavedSearchesRepository(apiClient: ref.watch(apiClientProvider));
});

final savedSearchesProvider = FutureProvider.autoDispose<List<SavedSearch>>((ref) {
  return ref.watch(savedSearchesRepositoryProvider).list();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../listings/application/listings_providers.dart' show SearchResultsState;
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(apiClient: ref.watch(apiClientProvider));
});

/// Just the set of favorited listing ids — cheap enough to keep resident so
/// every `PropertyCard`/Listing Detail heart icon can check membership
/// without each doing its own network round-trip. Fetches every page once
/// (favorite counts are small; this mirrors how a mobile app, unlike the
/// web's per-page query, keeps this kind of small membership set local).
/// Guests get an empty set with no network call — every `PropertyCard`
/// watches this, and the endpoint requires auth.
class FavoriteIdsController extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() async {
    if (ref.watch(authControllerProvider).valueOrNull == null) return {};

    final repo = ref.read(favoritesRepositoryProvider);
    final ids = <int>{};
    var page = 1;
    while (true) {
      final result = await repo.list(page: page);
      ids.addAll(result.items.map((listing) => listing.id));
      if (!result.hasMore) break;
      page++;
    }
    return ids;
  }

  Future<void> toggle(int listingId) async {
    final current = state.valueOrNull ?? <int>{};
    final wasFavorited = current.contains(listingId);
    final optimistic = Set<int>.from(current);
    wasFavorited ? optimistic.remove(listingId) : optimistic.add(listingId);
    state = AsyncData(optimistic);

    try {
      final repo = ref.read(favoritesRepositoryProvider);
      if (wasFavorited) {
        await repo.remove(listingId);
      } else {
        await repo.add(listingId);
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final favoriteIdsProvider = AsyncNotifierProvider<FavoriteIdsController, Set<int>>(
  FavoriteIdsController.new,
);

/// The "Saved" screen's own paginated list — a plain fetch-and-load-more,
/// same shape as Search's results but with no filters.
class FavoritesListController extends AsyncNotifier<SearchResultsState> {
  @override
  Future<SearchResultsState> build() async {
    final result = await ref.read(favoritesRepositoryProvider).list(page: 1);
    return SearchResultsState(items: result.items, page: result.currentPage, hasMore: result.hasMore, total: result.total);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await ref.read(favoritesRepositoryProvider).list(page: current.page + 1);
    state = AsyncData(
      SearchResultsState(
        items: [...current.items, ...result.items],
        page: result.currentPage,
        hasMore: result.hasMore,
        total: result.total,
      ),
    );
  }

  /// Removes a listing from view immediately after an un-favorite, rather
  /// than waiting for a full refetch.
  void removeLocally(int listingId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.where((l) => l.id != listingId).toList()));
  }
}

final favoritesListProvider = AsyncNotifierProvider<FavoritesListController, SearchResultsState>(
  FavoritesListController.new,
);

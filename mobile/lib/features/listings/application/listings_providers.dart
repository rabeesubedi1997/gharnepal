import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/listings_repository.dart';
import '../data/models/amenity.dart';
import '../data/models/listing_detail.dart';
import '../data/models/listing_summary.dart';
import '../data/models/search_filters.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(apiClient: ref.watch(apiClientProvider));
});

/// The Search screen's current filter set — a single shared source of truth
/// so the filter sheet and result list stay in sync, mirroring the web's
/// URL-query-param-driven `FilterPanel`.
final searchFiltersProvider = StateProvider<SearchFilters>((ref) => const SearchFilters());

class SearchResultsState {
  SearchResultsState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
    this.isLoadingMore = false,
  });

  final List<ListingSummary> items;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoadingMore;

  SearchResultsState copyWith({List<ListingSummary>? items, int? page, bool? hasMore, bool? isLoadingMore}) {
    return SearchResultsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Loads the first page for a given filter set on `build`, and appends
/// further pages via [loadMore] — the paginated-list equivalent of the
/// website's `useListingSearch` + "load more" pattern.
class SearchResultsController extends FamilyAsyncNotifier<SearchResultsState, SearchFilters> {
  @override
  Future<SearchResultsState> build(SearchFilters filters) async {
    final result = await ref.read(listingsRepositoryProvider).search(filters, page: 1);
    return SearchResultsState(
      items: result.items,
      page: result.currentPage,
      hasMore: result.hasMore,
      total: result.total,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await ref.read(listingsRepositoryProvider).search(arg, page: current.page + 1);
    state = AsyncData(
      SearchResultsState(
        items: [...current.items, ...result.items],
        page: result.currentPage,
        hasMore: result.hasMore,
        total: result.total,
      ),
    );
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.family<SearchResultsController, SearchResultsState, SearchFilters>(
      SearchResultsController.new,
    );

final listingDetailProvider = FutureProvider.family<ListingDetail, String>((ref, slug) {
  return ref.read(listingsRepositoryProvider).detail(slug);
});

final amenitiesProvider = FutureProvider<List<Amenity>>((ref) {
  return ref.read(listingsRepositoryProvider).amenities();
});

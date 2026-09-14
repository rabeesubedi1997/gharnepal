import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/agency_dashboard_repository.dart';
import '../data/models/agency_dashboard_listing.dart';
import '../data/models/agency_inquiry.dart';
import '../data/models/agency_overview.dart';
import '../data/models/agency_site_visit.dart';

final agencyDashboardRepositoryProvider = Provider<AgencyDashboardRepository>((ref) {
  return AgencyDashboardRepository(apiClient: ref.watch(apiClientProvider));
});

final agencyOverviewProvider = FutureProvider.autoDispose<AgencyOverview>((ref) {
  return ref.watch(agencyDashboardRepositoryProvider).overview();
});

final agencyInquiriesProvider = FutureProvider.autoDispose<List<AgencyInquiry>>((ref) {
  return ref.watch(agencyDashboardRepositoryProvider).inquiries();
});

final agencySiteVisitsProvider = FutureProvider.autoDispose<List<AgencySiteVisit>>((ref) {
  return ref.watch(agencyDashboardRepositoryProvider).siteVisits();
});

/// The Listings tab's current category/search/sort — mirrors
/// `Agency\DashboardController::listings`'s validated query params.
class AgencyListingsFilter {
  const AgencyListingsFilter({this.category, this.search, this.sort = 'newest'});

  final String? category; // houses | land | commercial
  final String? search;
  final String sort; // newest | leads | price_high | price_low

  AgencyListingsFilter copyWith({
    String? category,
    bool clearCategory = false,
    String? search,
    bool clearSearch = false,
    String? sort,
  }) {
    return AgencyListingsFilter(
      category: clearCategory ? null : (category ?? this.category),
      search: clearSearch ? null : (search ?? this.search),
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AgencyListingsFilter && other.category == category && other.search == search && other.sort == sort;

  @override
  int get hashCode => Object.hash(category, search, sort);
}

class AgencyListingsState {
  AgencyListingsState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
    this.isLoadingMore = false,
  });

  final List<AgencyDashboardListing> items;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoadingMore;

  AgencyListingsState copyWith({List<AgencyDashboardListing>? items, int? page, bool? hasMore, bool? isLoadingMore}) {
    return AgencyListingsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Loads the first page for a given filter on `build`, appends further
/// pages via [loadMore] — same shape as `listings/application/listings_providers.dart`'s
/// `SearchResultsController`.
class AgencyListingsController extends FamilyAsyncNotifier<AgencyListingsState, AgencyListingsFilter> {
  @override
  Future<AgencyListingsState> build(AgencyListingsFilter filter) async {
    final result = await ref
        .read(agencyDashboardRepositoryProvider)
        .listings(category: filter.category, search: filter.search, sort: filter.sort, page: 1);
    return AgencyListingsState(
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
    final result = await ref
        .read(agencyDashboardRepositoryProvider)
        .listings(category: arg.category, search: arg.search, sort: arg.sort, page: current.page + 1);
    state = AsyncData(
      AgencyListingsState(
        items: [...current.items, ...result.items],
        page: result.currentPage,
        hasMore: result.hasMore,
        total: result.total,
      ),
    );
  }
}

final agencyListingsProvider =
    AsyncNotifierProvider.family<AgencyListingsController, AgencyListingsState, AgencyListingsFilter>(
      AgencyListingsController.new,
    );

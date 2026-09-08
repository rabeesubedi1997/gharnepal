import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../../../listings/data/models/listing_detail.dart';
import '../data/admin_listings_repository.dart';

final adminListingsRepositoryProvider = Provider<AdminListingsRepository>((ref) {
  return AdminListingsRepository(apiClient: ref.watch(apiClientProvider));
});

final adminListingsStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'pending_review');
final adminListingsPageProvider = StateProvider.autoDispose<int>((ref) => 1);

/// There is no single-listing GET on this admin controller, so the detail
/// screen (`/admin/listings/:id`) reads from whatever the list screen has
/// already fetched, keyed by id — populated as a side effect of
/// [adminListingsProvider] and refreshed after approve/reject.
class AdminListingsCache extends Notifier<Map<int, ListingDetail>> {
  @override
  Map<int, ListingDetail> build() => {};

  void put(ListingDetail listing) => state = {...state, listing.id: listing};

  void putAll(Iterable<ListingDetail> listings) {
    state = {...state, for (final listing in listings) listing.id: listing};
  }
}

final adminListingsCacheProvider = NotifierProvider<AdminListingsCache, Map<int, ListingDetail>>(
  AdminListingsCache.new,
);

final adminListingsProvider = FutureProvider.autoDispose<PaginatedResult<ListingDetail>>((ref) async {
  final status = ref.watch(adminListingsStatusFilterProvider);
  final page = ref.watch(adminListingsPageProvider);
  final result = await ref.read(adminListingsRepositoryProvider).list(status: status, page: page);
  ref.read(adminListingsCacheProvider.notifier).putAll(result.items);
  return result;
});

/// A synchronous cache lookup, not a network fetch — the admin listing
/// detail screen is only ever reached by tapping a row already loaded by
/// [adminListingsProvider], so the cache is populated by the time this is
/// read. Returns `null` if the id isn't cached (e.g. a cold deep link).
final adminListingByIdProvider = Provider.autoDispose.family<ListingDetail?, int>((ref, id) {
  return ref.watch(adminListingsCacheProvider)[id];
});

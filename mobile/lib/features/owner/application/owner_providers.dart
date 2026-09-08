import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../listings/data/models/property.dart';
import '../data/models/listing_analytics.dart';
import '../data/owner_repository.dart';
import '../../listings/data/models/listing_detail.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository(apiClient: ref.watch(apiClientProvider));
});

/// The Owner Dashboard's "My Properties" list — first page only, mirroring
/// the same simplification used for the Property Requests board/mine lists
/// in Phase 3 (an owner's own portfolio is realistically small).
final myPropertiesProvider = FutureProvider.autoDispose<List<Property>>((ref) async {
  final result = await ref.read(ownerRepositoryProvider).myProperties();
  return result.items;
});

/// Fetched lazily — only once the owner taps "View stats" on a card, same
/// as the website's `useListingAnalytics(id, enabled)`.
final listingAnalyticsProvider = FutureProvider.autoDispose.family<ListingAnalytics, int>((ref, listingId) {
  return ref.read(ownerRepositoryProvider).analytics(listingId);
});

/// Backs the Edit Listing screen.
final ownerListingProvider = FutureProvider.autoDispose.family<ListingDetail, int>((ref, listingId) {
  return ref.read(ownerRepositoryProvider).ownerListing(listingId);
});

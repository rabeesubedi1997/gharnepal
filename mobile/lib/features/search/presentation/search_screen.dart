import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/skeleton.dart';
import '../../listings/application/listings_providers.dart';
import '../../listings/data/models/listing_summary.dart';
import 'filter_sheet.dart';

/// Search/browse: filters + a list/map toggle, mirroring
/// frontend/src/pages/Search/index.tsx. Filters live in `searchFiltersProvider`
/// (set by Home's search bar / city grid) rather than URL query params —
/// there's no shareable-search-URL requirement for the native app.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final results = ref.watch(searchResultsProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.view_list : Icons.map_outlined),
            tooltip: _showMap ? 'List view' : 'Map view',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: () async {
              final updated = await FilterSheet.show(context, filters);
              if (updated != null) ref.read(searchFiltersProvider.notifier).state = updated;
            },
          ),
        ],
      ),
      body: results.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Skeleton(height: 220, borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        error: (error, _) => ErrorState(
          message: 'Could not load listings. Please try again.',
          onRetry: () => ref.invalidate(searchResultsProvider(filters)),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const EmptyState(
              title: 'No listings match your filters',
              message: 'Try widening your price range or removing a filter.',
              icon: Icons.search_off,
            );
          }
          return _showMap
              ? _ResultsMap(listings: state.items)
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 300) {
                      ref.read(searchResultsProvider(filters).notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final listing = state.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PropertyCard(
                          listing: listing,
                          onTap: () => context.push('/listings/${listing.slug}'),
                        ),
                      );
                    },
                  ),
                );
        },
      ),
    );
  }
}

class _ResultsMap extends StatelessWidget {
  const _ResultsMap({required this.listings});

  final List<ListingSummary> listings;

  @override
  Widget build(BuildContext context) {
    final withCoords = listings.where((l) => l.location?.lat != null && l.location?.lng != null).toList();

    if (withCoords.isEmpty) {
      return const EmptyState(
        title: 'No mapped listings',
        message: 'None of these listings have a location pin yet.',
        icon: Icons.map_outlined,
      );
    }

    final center = LatLng(withCoords.first.location!.lat!, withCoords.first.location!.lng!);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.gharnepal.ghar_nepal',
        ),
        MarkerLayer(
          markers: withCoords
              .map(
                (listing) => Marker(
                  point: LatLng(listing.location!.lat!, listing.location!.lng!),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => context.push('/listings/${listing.slug}'),
                    child: const Icon(Icons.location_on, color: AppColors.trust700, size: 36),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

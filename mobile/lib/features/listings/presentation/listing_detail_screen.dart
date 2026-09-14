import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../features/calculators/application/calculators_providers.dart';
import '../../../features/messaging/presentation/start_conversation_sheet.dart';
import '../../../features/neighborhoods/application/neighborhoods_providers.dart';
import '../../../features/neighborhoods/data/models/neighborhood_poi.dart';
import '../../../features/viewing_requests/presentation/request_viewing_sheet.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/trust_badge.dart';
import '../application/listings_providers.dart';
import '../data/models/address.dart';
import '../data/models/land_profile.dart';
import '../data/models/listing_detail.dart';
import '../data/models/media_item.dart';
import '../data/models/property.dart';
import 'ratings_section.dart';
import 'report_listing_sheet.dart';

const _kParkingTypeLabel = {'car': 'Car', 'bike': 'Bike/scooter', 'both': 'Car & bike'};

const _kFacingDirectionLabel = {
  'north': 'North',
  'south': 'South',
  'east': 'East',
  'west': 'West',
  'northeast': 'Northeast',
  'northwest': 'Northwest',
  'southeast': 'Southeast',
  'southwest': 'Southwest',
};

// Mirrors distanceMeters()/formatDistance() in frontend/src/pages/ListingDetail.tsx.
double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000;
  double toRad(double d) => d * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) + math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String _formatDistance(double meters) {
  return meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
}

/// Mirrors frontend/src/pages/ListingDetail.tsx: gallery, price/area (incl.
/// Nepali land units), amenities, ratings & reviews, land due-diligence
/// checklist, trust badge, similar listings, a WhatsApp deep link to the
/// poster, share/report actions, and "Message owner"/"Request a viewing"
/// actions (guests are sent to login first).
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(listingDetailProvider(slug));

    return Scaffold(
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorState(
            message: 'Could not load this listing.',
            onRetry: () => ref.invalidate(listingDetailProvider(slug)),
          ),
        ),
        data: (listing) => _ListingDetailBody(listing: listing),
      ),
    );
  }
}

class _ListingDetailBody extends ConsumerWidget {
  const _ListingDetailBody({required this.listing});

  final ListingDetail listing;

  Future<void> _messageOwner(BuildContext context, WidgetRef ref) async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      context.push('/login');
      return;
    }
    final conversationId = await StartConversationSheet.show(
      context,
      listingId: listing.id,
      title: 'Message ${listing.poster?.name ?? 'the owner'}',
    );
    if (conversationId != null && context.mounted) {
      context.push('/messages/$conversationId');
    }
  }

  Future<void> _requestViewing(BuildContext context, WidgetRef ref) async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      context.push('/login');
      return;
    }
    final requested = await RequestViewingSheet.show(context, listing.id);
    if (requested == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Viewing request sent.')));
    }
  }

  /// Shares a link to the *web* listing page — mirrors
  /// frontend/src/pages/ListingDetail.tsx's `handleShare` (Web Share API
  /// there, the OS share sheet here). Recipients almost never have this app
  /// installed, so the shared link points at the public website, not a
  /// deep link into the app.
  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${listing.title}\n${ApiConfig.webBaseUrl}/listings/${listing.slug}',
        subject: listing.title,
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      context.push('/login');
      return;
    }
    final reported = await ReportListingSheet.show(context, listing.id);
    if (reported == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanks — our team will review this listing.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = listing.property.images;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          actions: [
            IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined), tooltip: 'Share listing'),
            FavoriteButton(listingId: listing.id),
            IconButton(
              onPressed: () => _report(context, ref),
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Report listing',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: images.isEmpty
                ? Container(color: AppColors.stone200, child: const Icon(Icons.home_outlined, size: 48))
                : PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: images[index].url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.stone200),
                    ),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Breadcrumb(listing: listing),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (listing.isFeatured) ...[
                      const AppBadge(label: 'Featured', tone: BadgeTone.accent),
                      const SizedBox(width: 8),
                    ],
                    if (listing.isClosed)
                      AppBadge(label: listing.status == 'sold' ? 'Sold' : 'Rented', tone: BadgeTone.neutral),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${NprFormatter.format(listing.price)}${listing.priceSuffix}',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
                ),
                if (listing.negotiable)
                  Text('Negotiable', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
                if (listing.priceHistory.length > 1) _PriceHistoryDisclosure(history: listing.priceHistory),
                const SizedBox(height: 8),
                Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${listing.referenceCode} · ${listing.viewsCount} view${listing.viewsCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                ),
                if (listing.property.address != null && listing.property.address!.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.ink700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.property.address!.summary,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink700),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _FactsRow(property: listing.property),
                if (listing.availabilityDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Available from ${listing.availabilityDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                  ),
                ],
                if (listing.rating.count > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: AppColors.warning600),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.rating.average?.toStringAsFixed(1)} · ${listing.rating.count} review${listing.rating.count == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if (listing.trust != null) ...[
                  const SizedBox(height: 16),
                  TrustBadge(trust: listing.trust!),
                ],
                if (!listing.isClosed) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Message owner',
                          variant: AppButtonVariant.outlined,
                          onPressed: () => _messageOwner(context, ref),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Request a viewing',
                          onPressed: () => _requestViewing(context, ref),
                        ),
                      ),
                    ],
                  ),
                ],
                if (listing.description != null && listing.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Description', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(listing.description!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (listing.videoTour != null) ...[
                  const SizedBox(height: 20),
                  Text('Video tour', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(listing.videoTour!.url), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch video tour'),
                  ),
                ],
                if (listing.purpose == 'sale') ...[
                  const SizedBox(height: 20),
                  _MortgageEstimate(propertyPrice: listing.price),
                ],
                if (listing.property.structuralNotes != null || listing.property.waterTankCapacityLiters != null) ...[
                  const SizedBox(height: 20),
                  Text('Architectural & Structural Overview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (listing.property.waterTankCapacityLiters != null)
                    Text(
                      'Water tank capacity: ${listing.property.waterTankCapacityLiters} litres',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (listing.property.structuralNotes != null) ...[
                    const SizedBox(height: 4),
                    Text(listing.property.structuralNotes!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
                if (listing.property.floorBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Floor-by-Floor Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final floor in listing.property.floorBreakdown) _FloorBreakdownTile(floor: floor),
                ],
                const SizedBox(height: 20),
                RatingsSection(listingId: listing.id, slug: listing.slug, myRating: listing.myRating),
                if (listing.amenities.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: listing.amenities
                        .map((amenity) => Chip(label: Text(amenity.name), backgroundColor: AppColors.stone100))
                        .toList(),
                  ),
                ],
                if (listing.property.floorPlans.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Floor plan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final plan in listing.property.floorPlans) _FloorPlanTile(plan: plan),
                ],
                if (listing.property.landProfile != null) ...[
                  const SizedBox(height: 20),
                  Text('Land due-diligence', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _LandDueDiligence(landProfile: listing.property.landProfile!),
                ],
                if (listing.property.address?.neighborhood != null) ...[
                  const SizedBox(height: 20),
                  _NeighborhoodAccessibility(
                    neighborhoodId: listing.property.address!.neighborhood!.id,
                    lat: listing.property.address!.lat,
                    lng: listing.property.address!.lng,
                  ),
                ],
                if (listing.property.address?.hasCoordinates ?? false) ...[
                  const SizedBox(height: 20),
                  Text('Map', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _ListingMiniMap(address: listing.property.address!),
                ],
                if (listing.poster != null) ...[
                  const SizedBox(height: 20),
                  Text('Posted by', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _PosterCard(listing: listing),
                ],
                if (listing.similarListings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Similar listings', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: listing.similarListings.length,
                      separatorBuilder: (context, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final similar = listing.similarListings[index];
                        return SizedBox(
                          width: 220,
                          child: PropertyCard(
                            listing: similar,
                            onTap: () => context.push('/listings/${similar.slug}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    final address = listing.property.address;
    final crumbs = <String>[
      'Home',
      if (address?.municipality != null) address!.municipality!.name,
      if (address?.neighborhood != null) address!.neighborhood!.name,
    ];

    return Text(
      '${crumbs.join(' / ')} / ${listing.referenceCode}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.ink700),
    );
  }
}

class _PriceHistoryDisclosure extends StatelessWidget {
  const _PriceHistoryDisclosure({required this.history});

  final List<PriceHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final sorted = [...history]..sort((a, b) => a.changedAt.compareTo(b.changedAt));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Price history (${sorted.length})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.trust700, fontWeight: FontWeight.w600),
        ),
        children: [
          for (final entry in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.changedAt, style: Theme.of(context).textTheme.bodySmall),
                  Text(NprFormatter.format(entry.price), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Real mortgage/EMI estimate reusing the existing purchase-calculator
/// endpoint (`CalculatorsRepository.calculatePurchase`) rather than
/// reimplementing the finance math client-side.
class _MortgageEstimate extends ConsumerStatefulWidget {
  const _MortgageEstimate({required this.propertyPrice});

  final double propertyPrice;

  @override
  ConsumerState<_MortgageEstimate> createState() => _MortgageEstimateState();
}

class _MortgageEstimateState extends ConsumerState<_MortgageEstimate> {
  double? _monthlyRepayment;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ref
          .read(calculatorsRepositoryProvider)
          .calculatePurchase(propertyPrice: widget.propertyPrice);
      if (mounted) setState(() => _monthlyRepayment = result.result.monthlyRepaymentEstimate);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.calculate_outlined, color: AppColors.trust700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated EMI', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
                  _loading
                      ? const Skeleton(width: 100, height: 20)
                      : Text(
                          '${NprFormatter.format(_monthlyRepayment ?? 0)}/mo',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                ],
              ),
            ),
            TextButton(onPressed: () => context.push('/calculators'), child: const Text('Full calculator')),
          ],
        ),
      ),
    );
  }
}

class _FloorBreakdownTile extends StatelessWidget {
  const _FloorBreakdownTile({required this.floor});

  final FloorBreakdownEntry floor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(floor.label ?? 'Floor', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (floor.description != null && floor.description!.isNotEmpty)
                  Text(
                    floor.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                  ),
              ],
            ),
          ),
          if (floor.areaSqft != null)
            Text('${floor.areaSqft!.toStringAsFixed(0)} sqft', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FloorPlanTile extends StatelessWidget {
  const _FloorPlanTile({required this.plan});

  final MediaItem plan;

  @override
  Widget build(BuildContext context) {
    if (plan.isPdf) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse(plan.url), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('View floor plan (PDF)'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(imageUrl: plan.url, fit: BoxFit.contain),
      ),
    );
  }
}

/// Real curated neighborhood score + nearest POIs by haversine distance from
/// this listing's own coordinates — mirrors `NeighborhoodAccessibility` in
/// frontend/src/pages/ListingDetail.tsx. Renders nothing if the neighborhood
/// has no curated score/POIs yet, rather than fabricating a "walk score".
class _NeighborhoodAccessibility extends ConsumerWidget {
  const _NeighborhoodAccessibility({required this.neighborhoodId, this.lat, this.lng});

  final int neighborhoodId;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(neighborhoodProfileProvider(neighborhoodId));

    return profile.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final pois = data.pois.where((p) => p.lat != null && p.lng != null).toList();
        if (data.score == null && pois.isEmpty) return const SizedBox.shrink();

        List<(NeighborhoodPoi, double)> nearest = [];
        if (lat != null && lng != null) {
          nearest = pois.map((p) => (p, _distanceMeters(lat!, lng!, p.lat!, p.lng!))).toList()
            ..sort((a, b) => a.$2.compareTo(b.$2));
          nearest = nearest.take(4).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Neighborhood & Accessibility', style: Theme.of(context).textTheme.titleMedium),
                ),
                if (data.score != null) ...[
                  const SizedBox(width: 8),
                  AppBadge(label: '${data.score!.overallScore}/10 score', tone: BadgeTone.trust),
                ],
              ],
            ),
            if (nearest.isNotEmpty) ...[
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  for (final (poi, distance) in nearest)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.stone200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            poi.typeLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.ink700),
                          ),
                          Text(
                            _formatDistance(distance),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            poi.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            InkWell(
              onTap: () => context.push('/neighborhoods/$neighborhoodId'),
              child: Text(
                'View full neighborhood profile →',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.trust700, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListingMiniMap extends StatelessWidget {
  const _ListingMiniMap({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(address.lat!, address.lng!);

    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.gharnepal.ghar_nepal',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: AppColors.trust700, size: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (property.bedrooms != null) (Icons.bed_outlined, '${property.bedrooms} bed'),
      if (property.bathrooms != null) (Icons.bathtub_outlined, '${property.bathrooms} bath'),
      if (property.floors != null) (Icons.layers_outlined, '${property.floors} floor${property.floors == 1 ? '' : 's'}'),
      if (property.area.sqm != null) (Icons.straighten, '${property.area.sqm!.toStringAsFixed(0)} m²'),
      if (property.area.display?['ropani'] != null)
        (Icons.terrain, '${property.area.display!['ropani']!.toStringAsFixed(2)} ropani'),
      if (property.area.display?['aana'] != null)
        (Icons.terrain, '${property.area.display!['aana']!.toStringAsFixed(2)} aana'),
      if (property.facingDirection != null)
        (Icons.explore_outlined, '${_kFacingDirectionLabel[property.facingDirection] ?? property.facingDirection} facing'),
      if (property.parkingSpaces != null && property.parkingSpaces! > 0)
        (
          Icons.local_parking_outlined,
          '${property.parkingSpaces} parking${property.parkingType != null ? ' (${_kParkingTypeLabel[property.parkingType] ?? property.parkingType})' : ''}',
        ),
    ];

    if (facts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: facts
          .map(
            (fact) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fact.$1, size: 18, color: AppColors.ink700),
                const SizedBox(width: 4),
                Text(fact.$2, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _LandDueDiligence extends StatelessWidget {
  const _LandDueDiligence({required this.landProfile});

  final LandProfile landProfile;

  @override
  Widget build(BuildContext context) {
    // Tri-state: true (confirmed good) / false (confirmed bad) / null
    // (genuinely unknown or in progress) — "unknown" must never render the
    // same red "confirmed bad" icon as an actual "no", or the checklist
    // overstates what's actually been verified.
    bool? tri(String value, {required String good, String? bad}) {
      if (value == good) return true;
      if (bad == null || value == bad) return false;
      return null;
    }

    final rows = <(String, String, bool?)>[
      (
        'Lalpurja (ownership certificate)',
        _label(landProfile.lalpurjaAvailable),
        tri(landProfile.lalpurjaAvailable, good: 'yes', bad: 'no'),
      ),
      ('Road access', landProfile.roadAccess ? 'Yes (${landProfile.roadType})' : 'No', landProfile.roadAccess),
      ('Electricity', landProfile.electricityAccess ? 'Connected' : 'Not connected', landProfile.electricityAccess),
      ('Water access', _label(landProfile.waterAccess), tri(landProfile.waterAccess, good: 'municipal', bad: 'none')),
      ('Drainage', _label(landProfile.drainageAccess), tri(landProfile.drainageAccess, good: 'yes', bad: 'no')),
      ('Flood risk', _label(landProfile.floodRisk), _riskTier(landProfile.floodRisk)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      row.$3 == null
                          ? Icons.help_outline
                          : row.$3!
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 18,
                      color: row.$3 == null
                          ? AppColors.ink700
                          : row.$3!
                          ? AppColors.success600
                          : AppColors.danger600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(row.$1, style: Theme.of(context).textTheme.bodyMedium)),
                    Text(
                      row.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            if (landProfile.documentVerificationStatus == 'verified')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: AppColors.success600),
                    const SizedBox(width: 6),
                    Text(
                      'Documents verified by Ghar Nepal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _label(String value) => value.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

  // none/low read as confirmed-good, medium/high as confirmed-bad, and
  // "unknown" stays neutral rather than being lumped in with either.
  bool? _riskTier(String risk) {
    if (risk == 'none' || risk == 'low') return true;
    if (risk == 'unknown') return null;
    return false;
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    final poster = listing.poster!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.trust100,
              child: Text(
                poster.name.isNotEmpty ? poster.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.trust700, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poster.name, style: Theme.of(context).textTheme.titleSmall),
                  if (poster.isAgency)
                    Text(poster.agencyName!, style: Theme.of(context).textTheme.bodySmall)
                  else if (poster.memberSince != null)
                    Text(
                      'Member since ${poster.memberSince}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                    ),
                ],
              ),
            ),
            if (poster.whatsappUrl != null)
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.success600),
                icon: const Icon(Icons.chat, color: Colors.white),
                tooltip: 'Message on WhatsApp',
                onPressed: () => launchUrl(Uri.parse(poster.whatsappUrl!), mode: LaunchMode.externalApplication),
              ),
          ],
        ),
      ),
    );
  }
}

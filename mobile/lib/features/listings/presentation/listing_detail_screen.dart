import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/trust_badge.dart';
import '../application/listings_providers.dart';
import '../data/models/land_profile.dart';
import '../data/models/listing_detail.dart';
import '../data/models/property.dart';

/// Mirrors frontend/src/pages/ListingDetail.tsx: gallery, price/area (incl.
/// Nepali land units), amenities, land due-diligence checklist, trust badge,
/// similar listings, and a WhatsApp deep link to the poster. "Message
/// owner"/"Request a viewing" are added in Phase 3 once the messaging and
/// viewing-request backends are wired up — this screen is browsing-only.
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

class _ListingDetailBody extends StatelessWidget {
  const _ListingDetailBody({required this.listing});

  final ListingDetail listing;

  @override
  Widget build(BuildContext context) {
    final images = listing.property.images;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
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
                const SizedBox(height: 8),
                Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  listing.referenceCode,
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
                if (listing.description != null && listing.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Description', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(listing.description!, style: Theme.of(context).textTheme.bodyMedium),
                ],
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
                if (listing.property.landProfile != null) ...[
                  const SizedBox(height: 20),
                  Text('Land due-diligence', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _LandDueDiligence(landProfile: listing.property.landProfile!),
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

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (property.bedrooms != null) (Icons.bed_outlined, '${property.bedrooms} bed'),
      if (property.bathrooms != null) (Icons.bathtub_outlined, '${property.bathrooms} bath'),
      if (property.area.sqm != null) (Icons.straighten, '${property.area.sqm!.toStringAsFixed(0)} m²'),
      if (property.area.display?['ropani'] != null)
        (Icons.terrain, '${property.area.display!['ropani']!.toStringAsFixed(2)} ropani'),
      if (property.area.display?['aana'] != null)
        (Icons.terrain, '${property.area.display!['aana']!.toStringAsFixed(2)} aana'),
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

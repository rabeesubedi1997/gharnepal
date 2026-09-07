import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/formatters/npr_formatter.dart';
import '../core/theme/app_colors.dart';
import '../features/listings/data/models/listing_summary.dart';
import 'app_badge.dart';
import 'trust_badge.dart';

/// Mirrors `frontend/src/components/property/PropertyCard.tsx`: cover image,
/// price, trust chip, rating stars, bed/bath/area icons, and a
/// featured/closed ribbon.
class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.listing, required this.onTap});

  final ListingSummary listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: listing.coverImageUrl != null
                      ? ColorFiltered(
                          colorFilter: listing.isClosed
                              ? const ColorFilter.mode(Colors.black38, BlendMode.darken)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: CachedNetworkImage(
                            imageUrl: listing.coverImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(color: AppColors.stone200),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.stone200, child: const Icon(Icons.image_not_supported)),
                          ),
                        )
                      : Container(
                          color: AppColors.stone200,
                          child: const Icon(Icons.home_outlined, size: 32, color: AppColors.ink700),
                        ),
                ),
                if (listing.isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AppBadge(label: 'Featured', tone: BadgeTone.accent),
                  ),
                if (listing.isClosed)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AppBadge(
                      label: listing.status == 'sold' ? 'Sold' : 'Rented',
                      tone: BadgeTone.neutral,
                    ),
                  ),
                if (listing.trustScore != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: TrustScoreChip(score: listing.trustScore!),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${NprFormatter.formatCompact(listing.price)}${listing.priceSuffix}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (listing.location != null && listing.location!.summary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      listing.location!.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (listing.bedrooms != null) _iconStat(context, Icons.bed_outlined, '${listing.bedrooms}'),
                      if (listing.bathrooms != null) _iconStat(context, Icons.bathtub_outlined, '${listing.bathrooms}'),
                      if (listing.areaSqm != null)
                        _iconStat(context, Icons.straighten, '${listing.areaSqm!.toStringAsFixed(0)} m²'),
                      const Spacer(),
                      if (listing.rating.average != null) ...[
                        const Icon(Icons.star, size: 14, color: AppColors.warning600),
                        const SizedBox(width: 2),
                        Text(
                          listing.rating.average!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconStat(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.ink700),
          const SizedBox(width: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
        ],
      ),
    );
  }
}

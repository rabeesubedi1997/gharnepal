import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../listings/data/models/property.dart';
import '../application/owner_providers.dart';
import 'feature_listing_sheet.dart';

/// Mirrors frontend/src/pages/Dashboard.tsx: "My Properties", one card per
/// `Property`, one row per listing on it (almost always exactly one), with
/// status-driven next-action buttons and on-demand per-listing analytics.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(myPropertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My properties')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-property'),
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Post property'),
      ),
      body: properties.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load your properties.',
          onRetry: () => ref.invalidate(myPropertiesProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                title: 'No properties yet',
                message: 'Tap "Post property" to list your first one.',
                icon: Icons.add_home_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myPropertiesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _PropertyCard(property: items[index]),
                ),
              ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final cover = property.images.isNotEmpty ? property.images.first.url : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: cover != null
                    ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover)
                    : Container(color: AppColors.stone200, child: const Icon(Icons.home_outlined)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleCase(property.propertyType),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (property.address != null && property.address!.summary.isNotEmpty)
                        Text(
                          property.address!.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (property.listings.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text('No listing created for this property yet.'),
            )
          else
            for (final listing in property.listings) _ListingRow(propertyId: property.id, listing: listing),
        ],
      ),
    );
  }

  String _titleCase(String value) => value[0].toUpperCase() + value.substring(1);
}

class _ListingRow extends ConsumerStatefulWidget {
  const _ListingRow({required this.propertyId, required this.listing});

  final int propertyId;
  final OwnerListingSummary listing;

  @override
  ConsumerState<_ListingRow> createState() => _ListingRowState();
}

class _ListingRowState extends ConsumerState<_ListingRow> {
  bool _busy = false;
  bool _showStats = false;

  BadgeTone _statusTone(String status) => switch (status) {
    'published' => BadgeTone.success,
    'paused' || 'pending_review' => BadgeTone.warning,
    'rented' || 'sold' => BadgeTone.trust,
    'rejected' || 'expired' => BadgeTone.danger,
    _ => BadgeTone.neutral,
  };

  /// Mirrors the backend's state machine —
  /// PropertyListingService::TRANSITIONS — one button per valid next action.
  List<(String action, String label)> _nextActions(String status) => switch (status) {
    'draft' => const [('submit', 'Submit for review')],
    'pending_review' => const [('withdraw', 'Withdraw')],
    'published' => const [('pause', 'Pause'), ('mark_rented', 'Mark rented'), ('mark_sold', 'Mark sold')],
    'paused' => const [('resume', 'Resume'), ('mark_rented', 'Mark rented'), ('mark_sold', 'Mark sold')],
    _ => const [],
  };

  Future<void> _transition(String action) async {
    setState(() => _busy = true);
    try {
      await ref.read(ownerRepositoryProvider).transitionListing(widget.listing.id, action);
      ref.invalidate(myPropertiesProvider);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final actions = _nextActions(listing.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(listing.title, style: Theme.of(context).textTheme.titleSmall)),
              if (listing.isFeatured) ...[
                const AppBadge(label: 'Featured', tone: BadgeTone.accent),
                const SizedBox(width: 6),
              ],
              AppBadge(label: listing.status.replaceAll('_', ' '), tone: _statusTone(listing.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${NprFormatter.format(listing.price)}${listing.purpose == 'rent' ? '/mo' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => context.push('/owner/listings/${listing.id}/edit'),
                child: const Text('Edit'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _showStats = !_showStats),
                child: Text(_showStats ? 'Hide stats' : 'View stats'),
              ),
              if (listing.status == 'published')
                OutlinedButton(
                  onPressed: () => FeatureListingSheet.show(context, listing.id),
                  child: const Text('Feature'),
                ),
              for (final action in actions)
                FilledButton.tonal(
                  onPressed: _busy ? null : () => _transition(action.$1),
                  child: Text(action.$2),
                ),
            ],
          ),
          if (_showStats) ...[
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final analytics = ref.watch(listingAnalyticsProvider(listing.id));
                return analytics.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Could not load stats.')),
                        TextButton(
                          onPressed: () => ref.invalidate(listingAnalyticsProvider(listing.id)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (stats) => Row(
                    children: [
                      _StatTile(icon: Icons.visibility_outlined, label: 'Views', value: stats.viewsCount),
                      _StatTile(icon: Icons.favorite_border, label: 'Favorites', value: stats.favoritesCount),
                      _StatTile(icon: Icons.chat_bubble_outline, label: 'Inquiries', value: stats.inquiriesCount),
                      _StatTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Viewings',
                        value: stats.viewingRequestsCount,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.ink700),
          const SizedBox(height: 2),
          Text('$value', style: Theme.of(context).textTheme.titleSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
        ],
      ),
    );
  }
}

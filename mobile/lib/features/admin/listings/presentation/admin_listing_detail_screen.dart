import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/npr_formatter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/empty_state.dart';
import '../../../listings/data/models/listing_detail.dart';
import '../application/admin_listings_providers.dart';

/// Admin listing detail (`/admin/listings/:id`) — looked up from the
/// moderation queue's own cache (see [adminListingByIdProvider]; there is no
/// single-listing GET on this admin controller). Shows Approve/Reject when
/// `pending_review`, plus cross-links into the trust-override and
/// land-profile screens owned by other agents.
class AdminListingDetailScreen extends ConsumerWidget {
  const AdminListingDetailScreen({super.key, required this.propertyListingId});

  final int propertyListingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(adminListingByIdProvider(propertyListingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Listing detail')),
      body: listing == null
          ? const EmptyState(
              title: 'Listing not loaded',
              message: 'Open this listing from the moderation queue list to view its details.',
              icon: Icons.fact_check_outlined,
            )
          : _ListingDetailBody(listing: listing),
    );
  }
}

class _ListingDetailBody extends ConsumerStatefulWidget {
  const _ListingDetailBody({required this.listing});

  final ListingDetail listing;

  @override
  ConsumerState<_ListingDetailBody> createState() => _ListingDetailBodyState();
}

class _ListingDetailBodyState extends ConsumerState<_ListingDetailBody> {
  final _reasonController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  BadgeTone _statusTone(String status) => switch (status) {
    'published' => BadgeTone.success,
    'paused' || 'pending_review' => BadgeTone.warning,
    'rented' || 'sold' => BadgeTone.trust,
    'rejected' || 'expired' => BadgeTone.danger,
    _ => BadgeTone.neutral, // draft
  };

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      final updated = await ref.read(adminListingsRepositoryProvider).approve(widget.listing.id);
      ref.read(adminListingsCacheProvider.notifier).put(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing approved.')));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _busy = true);
    try {
      final updated = await ref.read(adminListingsRepositoryProvider).reject(widget.listing.id, reason);
      ref.read(adminListingsCacheProvider.notifier).put(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing rejected.')));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Re-read the (possibly refreshed-by-cache) listing on every rebuild so
    // approve/reject results reflect immediately without popping the route.
    final listing = ref.watch(adminListingByIdProvider(widget.listing.id)) ?? widget.listing;
    final property = listing.property;
    final images = property.media.where((m) => m.type == 'image').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(imageUrl: images[index].url, width: 240, fit: BoxFit.cover),
              ),
            ),
          )
        else
          Container(
            height: 140,
            decoration: BoxDecoration(color: AppColors.stone200, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.home_outlined, size: 40),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(listing.title, style: Theme.of(context).textTheme.titleLarge),
            ),
            AppBadge(label: listing.status.replaceAll('_', ' '), tone: _statusTone(listing.status)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ref ${listing.referenceCode}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
        ),
        const SizedBox(height: 10),
        Text(
          '${NprFormatter.format(listing.price)}${listing.priceSuffix}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Property', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text('Type: ${property.propertyType}'),
                if (property.bedrooms != null) Text('Bedrooms: ${property.bedrooms}'),
                if (property.bathrooms != null) Text('Bathrooms: ${property.bathrooms}'),
                if (property.floors != null) Text('Floors: ${property.floors}'),
                if (property.area.sqm != null) Text('Area: ${property.area.sqm!.toStringAsFixed(2)} sqm'),
                if (property.address != null && property.address!.summary.isNotEmpty)
                  Text('Address: ${property.address!.summary}'),
                const SizedBox(height: 6),
                Text('Poster: ${listing.poster?.name ?? 'Unknown'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/admin/trust-override/${listing.id}'),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Trust score'),
            ),
            if (property.propertyType == 'land')
              OutlinedButton.icon(
                onPressed: () => context.push('/admin/land-profiles/${property.id}'),
                icon: const Icon(Icons.terrain_outlined),
                label: const Text('Land profile'),
              ),
          ],
        ),
        if (listing.status == 'pending_review') ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text('Moderate this listing', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          AppButton(label: 'Approve', isLoading: _busy, onPressed: _busy ? null : _approve),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Rejection reason', hintText: 'Required to reject'),
            onChanged: (_) => setState(() {}),
          ),
          AppButton(
            label: 'Reject',
            variant: AppButtonVariant.outlined,
            isLoading: _busy,
            onPressed: _busy || _reasonController.text.trim().isEmpty ? null : _reject,
          ),
        ],
      ],
    );
  }
}

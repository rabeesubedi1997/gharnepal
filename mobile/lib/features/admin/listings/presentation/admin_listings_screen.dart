import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/npr_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../listings/data/models/listing_detail.dart';
import '../application/admin_listings_providers.dart';
import '../data/admin_listings_repository.dart';

/// Admin listings moderation queue: `GET /admin/listings?status=` — an
/// oldest-first FIFO queue, defaulting to `pending_review`.
class AdminListingsScreen extends ConsumerWidget {
  const AdminListingsScreen({super.key});

  BadgeTone _statusTone(String status) => switch (status) {
    'published' => BadgeTone.success,
    'paused' || 'pending_review' => BadgeTone.warning,
    'rented' || 'sold' => BadgeTone.trust,
    'rejected' || 'expired' => BadgeTone.danger,
    _ => BadgeTone.neutral, // draft
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(adminListingsProvider);
    final page = ref.watch(adminListingsPageProvider);
    final status = ref.watch(adminListingsStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Listings moderation')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in kAdminListingStatuses) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(adminListingsStatusFilterProvider.notifier).state = value;
                ref.read(adminListingsPageProvider.notifier).state = 1;
              },
            ),
          ),
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load listings.',
                onRetry: () => ref.invalidate(adminListingsProvider),
              ),
              data: (result) => result.items.isEmpty
                  ? const EmptyState(title: 'No listings in this queue', icon: Icons.fact_check_outlined)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: result.items.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _ListingCard(
                              listing: result.items[index],
                              statusTone: _statusTone(result.items[index].status),
                            ),
                          ),
                        ),
                        if (result.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: page > 1
                                      ? () => ref.read(adminListingsPageProvider.notifier).state = page - 1
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                Text('Page $page of ${result.lastPage}'),
                                TextButton(
                                  onPressed: page < result.lastPage
                                      ? () => ref.read(adminListingsPageProvider.notifier).state = page + 1
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.statusTone});

  final ListingDetail listing;
  final BadgeTone statusTone;

  @override
  Widget build(BuildContext context) {
    final thumbnail = listing.property.media.isNotEmpty ? listing.property.media.first.url : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/listings/${listing.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail != null
                    ? CachedNetworkImage(imageUrl: thumbnail, width: 72, height: 72, fit: BoxFit.cover)
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.stone200,
                        child: const Icon(Icons.home_outlined),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        AppBadge(label: listing.status.replaceAll('_', ' '), tone: statusTone),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref ${listing.referenceCode} · ${listing.poster?.name ?? 'Unknown poster'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NprFormatter.format(listing.price)}${listing.priceSuffix}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

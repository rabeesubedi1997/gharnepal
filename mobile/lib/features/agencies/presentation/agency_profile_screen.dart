import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/property_card.dart';
import '../application/agencies_providers.dart';
import '../data/models/agency_profile.dart';

/// Mirrors frontend/src/pages/Agents/AgencyProfile.tsx: header card, member
/// chips, an active-listings grid, and (only when non-empty) a "track
/// record" section of recently closed deals as a trust signal.
class AgencyProfileScreen extends ConsumerWidget {
  const AgencyProfileScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agency = ref.watch(agencyProfileProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Agency')),
      body: agency.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load this agency.',
          onRetry: () => ref.invalidate(agencyProfileProvider(slug)),
        ),
        data: (data) => _ProfileBody(agency: data),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.agency});

  final AgencyProfile agency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.stone200,
                      backgroundImage: agency.logoUrl != null ? CachedNetworkImageProvider(agency.logoUrl!) : null,
                      child: agency.logoUrl == null ? const Icon(Icons.business_outlined, size: 28) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(agency.name, style: Theme.of(context).textTheme.titleLarge)),
                              if (agency.isVerified) ...[
                                const SizedBox(width: 6),
                                const AppBadge(label: 'Verified', tone: BadgeTone.success),
                              ],
                            ],
                          ),
                          if (agency.closedListingsCount > 0)
                            Text(
                              '${agency.closedListingsCount} closed deal(s)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (agency.description != null && agency.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(agency.description!),
                ],
                if (agency.members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: agency.members
                        .map((m) => Chip(label: Text(m.isAdmin ? '${m.name} · admin' : m.name)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Active listings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (agency.activeListings.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No active listings right now.'))
        else
          for (final listing in agency.activeListings)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PropertyCard(listing: listing, onTap: () => context.push('/listings/${listing.slug}')),
            ),
        if (agency.closedListings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Track record', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final listing in agency.closedListings)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PropertyCard(listing: listing, onTap: () => context.push('/listings/${listing.slug}')),
            ),
        ],
      ],
    );
  }
}

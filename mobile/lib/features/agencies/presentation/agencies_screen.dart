import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/agencies_providers.dart';
import '../data/models/agency_summary.dart';

/// Mirrors frontend/src/pages/Agents/index.tsx — a directory of verified,
/// active agencies (the only ones the public endpoint ever returns).
class AgenciesScreen extends ConsumerWidget {
  const AgenciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencies = ref.watch(agenciesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agents & agencies')),
      body: agencies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load agencies.',
          onRetry: () => ref.invalidate(agenciesListProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(title: 'No agencies listed yet', icon: Icons.business_outlined)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(agenciesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _AgencyTile(agency: items[index]),
                ),
              ),
      ),
    );
  }
}

class _AgencyTile extends StatelessWidget {
  const _AgencyTile({required this.agency});

  final AgencySummary agency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/agencies/${agency.slug}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.stone200,
          backgroundImage: agency.logoUrl != null ? CachedNetworkImageProvider(agency.logoUrl!) : null,
          child: agency.logoUrl == null ? const Icon(Icons.business_outlined) : null,
        ),
        title: Row(
          children: [
            Flexible(child: Text(agency.name, overflow: TextOverflow.ellipsis)),
            if (agency.isVerified) ...[
              const SizedBox(width: 6),
              const AppBadge(label: 'Verified', tone: BadgeTone.success),
            ],
          ],
        ),
        subtitle: Text(
          agency.description?.isNotEmpty == true
              ? agency.description!
              : '${agency.memberCount} agent(s) · ${agency.activeListingsCount} active listing(s)',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: agency.description?.isNotEmpty == true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

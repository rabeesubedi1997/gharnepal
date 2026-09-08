import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/npr_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../../presentation/admin_drawer.dart';
import '../application/admin_dashboard_providers.dart';
import '../data/models/admin_dashboard_stats.dart';

/// Admin console landing screen: `GET /admin/dashboard/stats` rendered as
/// stat cards grouped by section, plus a moderation-queue banner with
/// tappable rows into each queue's own screen.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      drawer: const AdminDrawer(),
      body: stats.when(
        loading: () => const _DashboardSkeleton(),
        error: (error, _) => ErrorState(
          message: 'Could not load dashboard stats.',
          onRetry: () => ref.invalidate(adminDashboardStatsProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDashboardStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ModerationQueueBanner(queue: data.moderationQueue),
              const SizedBox(height: 20),
              _SectionTitle('Listings'),
              _StatGrid(
                tiles: [
                  _StatTileData('Total', '${data.listings.total}'),
                  _StatTileData('Published', '${data.listings.published}'),
                  _StatTileData('Pending review', '${data.listings.pendingReview}'),
                  _StatTileData('Featured active', '${data.listings.featuredActive}'),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle('Users'),
              _StatGrid(
                tiles: [
                  _StatTileData('Total', '${data.users.total}'),
                  _StatTileData('Owners', '${data.users.owners}'),
                  _StatTileData('Agents', '${data.users.agents}'),
                  _StatTileData('Suspended', '${data.users.suspended}'),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle('Agencies'),
              _StatGrid(
                tiles: [
                  _StatTileData('Total', '${data.agencies.total}'),
                  _StatTileData('Verified', '${data.agencies.verified}'),
                  _StatTileData('Pending', '${data.agencies.pending}'),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle('Payments'),
              _StatGrid(
                tiles: [
                  _StatTileData('Completed', '${data.payments.completedCount}'),
                  _StatTileData('Completed amount', NprFormatter.formatCompact(data.payments.completedAmount)),
                  _StatTileData('Pending', '${data.payments.pending}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _StatTileData {
  const _StatTileData(this.label, this.value);

  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.tiles});

  final List<_StatTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tile.value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
                ),
                const SizedBox(height: 2),
                Text(tile.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModerationQueueBanner extends StatelessWidget {
  const _ModerationQueueBanner({required this.queue});

  final DashboardModerationQueueStats queue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.trust100,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.trust700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Moderation queue · ${queue.total} item${queue.total == 1 ? '' : 's'}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.trust700, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _QueueRow(label: 'Reports', count: queue.reports, onTap: () => context.push('/admin/reports')),
            _QueueRow(
              label: 'Duplicate flags',
              count: queue.duplicateFlags,
              onTap: () => context.push('/admin/duplicate-flags'),
            ),
            _QueueRow(
              label: 'Verifications',
              count: queue.verifications,
              onTap: () => context.push('/admin/verifications'),
            ),
            _QueueRow(
              label: 'Community notes',
              count: queue.communityNotes,
              onTap: () => context.push('/admin/community-notes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.label, required this.count, required this.onTap});

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text('$count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.trust700),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(height: 140, borderRadius: BorderRadius.all(Radius.circular(12))),
        SizedBox(height: 20),
        Skeleton(width: 100, height: 20),
        SizedBox(height: 10),
        Skeleton(height: 180, borderRadius: BorderRadius.all(Radius.circular(12))),
      ],
    );
  }
}

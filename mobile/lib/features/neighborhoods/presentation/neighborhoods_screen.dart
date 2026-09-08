import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/neighborhoods_providers.dart';
import '../data/models/neighborhood_summary.dart';

/// Mirrors frontend/src/pages/Neighborhoods/index.tsx: the full unpaginated
/// list is fetched once and filtered client-side — there is no server
/// search/pagination on this endpoint.
class NeighborhoodsScreen extends ConsumerStatefulWidget {
  const NeighborhoodsScreen({super.key});

  @override
  ConsumerState<NeighborhoodsScreen> createState() => _NeighborhoodsScreenState();
}

class _NeighborhoodsScreenState extends ConsumerState<NeighborhoodsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neighborhoods = ref.watch(neighborhoodsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Neighborhoods')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or city',
              ),
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: neighborhoods.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load neighborhoods.',
                onRetry: () => ref.invalidate(neighborhoodsListProvider),
              ),
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((n) => n.searchHaystack.contains(_query)).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(title: 'No neighborhoods found', icon: Icons.location_city_outlined);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(neighborhoodsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _NeighborhoodTile(neighborhood: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodTile extends StatelessWidget {
  const _NeighborhoodTile({required this.neighborhood});

  final NeighborhoodSummary neighborhood;

  @override
  Widget build(BuildContext context) {
    final score = neighborhood.score;

    return Card(
      child: ListTile(
        onTap: () => context.push('/neighborhoods/${neighborhood.id}'),
        title: Row(
          children: [
            Expanded(child: Text(neighborhood.name)),
            if (neighborhood.isCurated) ...[
              const AppBadge(label: 'Curated', tone: BadgeTone.trust),
              const SizedBox(width: 6),
            ],
          ],
        ),
        subtitle: Text('${neighborhood.ward.municipality} · Ward ${neighborhood.ward.wardNumber}'),
        trailing: score != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.overallScore}/10',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('score', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
                ],
              )
            : null,
      ),
    );
  }
}

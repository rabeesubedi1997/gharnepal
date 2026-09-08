import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/matching_providers.dart';
import '../data/models/match_result.dart';

/// Mirrors frontend/src/pages/Matching/MatchResults.tsx: a grid of scored
/// listings, each with a collapsible "Why this match?" breakdown.
class MatchResultsScreen extends ConsumerStatefulWidget {
  const MatchResultsScreen({super.key});

  @override
  ConsumerState<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends ConsumerState<MatchResultsScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(matchingRepositoryProvider).refreshResults();
      ref.invalidate(matchResultsProvider);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(matchPreferencesProvider);
    final results = ref.watch(matchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your matches'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Refresh matches',
            onPressed: _refreshing ? null : _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Edit preferences',
            onPressed: () => context.push('/match-preferences'),
          ),
        ],
      ),
      body: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load your preferences.',
          onRetry: () => ref.invalidate(matchPreferencesProvider),
        ),
        data: (prefs) {
          if (!prefs.hasSaved) {
            return EmptyState(
              title: 'Set your preferences to get matches',
              icon: Icons.tune,
              action: FilledButton(
                onPressed: () => context.push('/match-preferences'),
                child: const Text('Set preferences'),
              ),
            );
          }

          return results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Could not load your matches.',
              onRetry: () => ref.invalidate(matchResultsProvider),
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(
                    title: 'No matches yet',
                    message: 'Try widening your budget or dropping a must-have.',
                    icon: Icons.search_off,
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(matchResultsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _MatchResultCard(result: items[index]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard({required this.result});

  final MatchResult result;

  @override
  Widget build(BuildContext context) {
    final listing = result.listing;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push('/listings/${listing.slug}'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: listing.coverImageUrl != null
                      ? CachedNetworkImage(imageUrl: listing.coverImageUrl!, fit: BoxFit.cover)
                      : Container(color: AppColors.stone200, child: const Icon(Icons.home_outlined)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${NprFormatter.formatCompact(listing.price)}${listing.priceSuffix}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (listing.location != null)
                          Text(
                            listing.location!.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _ScoreBadge(score: result.score),
                ),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Why this match?'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final reason in result.reasons)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reason.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text(reason.explanation, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text('${reason.points}/${reason.maxPoints}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  Color get _color {
    if (score >= 70) return AppColors.success600;
    if (score >= 40) return AppColors.warning600;
    return AppColors.danger600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text('$score%', style: TextStyle(color: _color, fontWeight: FontWeight.w700)),
          Text('match', style: TextStyle(color: _color, fontSize: 10)),
        ],
      ),
    );
  }
}

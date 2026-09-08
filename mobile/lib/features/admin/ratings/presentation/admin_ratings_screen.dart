import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_ratings_providers.dart';
import '../data/models/rating.dart';

const _kStatusOptions = {'all': 'All', 'visible': 'Visible', 'hidden': 'Hidden'};

/// Mirrors the website's ratings moderation queue: a status filter (All
/// omits the query param entirely) plus a paginated (25/page) list with a
/// single hide/unhide action per rating.
class AdminRatingsScreen extends ConsumerStatefulWidget {
  const AdminRatingsScreen({super.key});

  @override
  ConsumerState<AdminRatingsScreen> createState() => _AdminRatingsScreenState();
}

class _AdminRatingsScreenState extends ConsumerState<AdminRatingsScreen> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final ratings = ref.watch(adminRatingsProvider(_status));

    return Scaffold(
      appBar: AppBar(title: const Text('Ratings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _kStatusOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
          ),
          Expanded(
            child: ratings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load ratings.',
                onRetry: () => ref.invalidate(adminRatingsProvider(_status)),
              ),
              data: (state) => state.items.isEmpty
                  ? const EmptyState(title: 'No ratings here', icon: Icons.star_border)
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(adminRatingsProvider(_status)),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 300) {
                            ref.read(adminRatingsProvider(_status).notifier).loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) => _RatingCard(rating: state.items[index], status: _status),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends ConsumerStatefulWidget {
  const _RatingCard({required this.rating, required this.status});

  final Rating rating;
  final String status;

  @override
  ConsumerState<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends ConsumerState<_RatingCard> {
  bool _busy = false;

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminRatingsRepositoryProvider);
      final updated = widget.rating.status == 'visible'
          ? await repo.hide(widget.rating.id)
          : await repo.unhide(widget.rating.id);
      ref.read(adminRatingsProvider(widget.status).notifier).updateItem(updated);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.rating;
    final isVisible = rating.status == 'visible';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating.score ? Icons.star : Icons.star_border,
                      size: 18,
                      color: AppColors.warning600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${rating.score}/5', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                AppBadge(
                  label: isVisible ? 'Visible' : 'Hidden',
                  tone: isVisible ? BadgeTone.success : BadgeTone.neutral,
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rating.comment!),
            ],
            const SizedBox(height: 8),
            Text(
              rating.user != null ? 'By ${rating.user!.name}' : 'By a deleted user',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            const SizedBox(height: 4),
            rating.listing != null
                ? InkWell(
                    onTap: () => context.push('/listings/${rating.listing!.slug}'),
                    child: Text(
                      rating.listing!.title,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.link600, fontWeight: FontWeight.w600),
                    ),
                  )
                : Text(
                    'Listing deleted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                  ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _toggle,
              style: isVisible ? OutlinedButton.styleFrom(foregroundColor: AppColors.danger600) : null,
              child: Text(isVisible ? 'Hide' : 'Unhide'),
            ),
          ],
        ),
      ),
    );
  }
}

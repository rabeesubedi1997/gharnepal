import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/skeleton.dart';
import '../application/listings_providers.dart';
import '../data/models/listing_detail.dart';

/// Mirrors the `RatingsSection` component on frontend/src/pages/ListingDetail.tsx:
/// a "Rate this listing"/"Edit your rating" toggle with a 1-5 star + optional
/// comment form, and the list of everyone else's visible reviews below it.
class RatingsSection extends ConsumerStatefulWidget {
  const RatingsSection({super.key, required this.listingId, required this.slug, this.myRating});

  final int listingId;
  final String slug;
  final MyRating? myRating;

  @override
  ConsumerState<RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends ConsumerState<RatingsSection> {
  static final _dateFormat = DateFormat('d MMM y');

  bool _formOpen = false;
  late int _score;
  late TextEditingController _commentController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _score = widget.myRating?.score ?? 0;
    _commentController = TextEditingController(text: widget.myRating?.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openForm() {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      context.push('/login');
      return;
    }
    setState(() => _formOpen = true);
  }

  void _refresh() {
    ref.invalidate(listingRatingsProvider(widget.listingId));
    ref.invalidate(listingDetailProvider(widget.slug));
  }

  Future<void> _submit() async {
    if (_score == 0) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(listingsRepositoryProvider)
          .rateListing(widget.listingId, score: _score, comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim());
      if (mounted) {
        setState(() => _formOpen = false);
        _refresh();
      }
    } catch (error) {
      setState(() => _error = error is ApiException ? error.message : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _submitting = true);
    try {
      await ref.read(listingsRepositoryProvider).deleteRating(widget.listingId);
      if (mounted) {
        setState(() {
          _formOpen = false;
          _score = 0;
          _commentController.clear();
        });
        _refresh();
      }
    } catch (error) {
      setState(() => _error = error is ApiException ? error.message : 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myRating = widget.myRating;
    final ratings = ref.watch(listingRatingsProvider(widget.listingId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ratings & reviews', style: Theme.of(context).textTheme.titleMedium),
            if (!_formOpen)
              OutlinedButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.star_outline, size: 16),
                label: Text(myRating != null ? 'Edit your rating' : 'Rate this listing'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_formOpen) _buildForm(context, myRating),
        if (_formOpen) const SizedBox(height: 12),
        ratings.when(
          loading: () => const Skeleton(height: 60),
          error: (error, _) => Text(
            'Could not load reviews.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'No reviews yet — be the first to share your experience.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink700),
              );
            }
            return Column(
              children: [
                for (final review in items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _StarRow(score: review.score, size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    review.user?.name ?? 'A user',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Text(
                                _dateFormat.format(DateTime.parse(review.createdAt)),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                              ),
                            ],
                          ),
                          if (review.comment != null && review.comment!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(review.comment!, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, MyRating? myRating) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var n = 1; n <= 5; n++)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _score = n),
                    icon: Icon(
                      n <= _score ? Icons.star : Icons.star_border,
                      color: AppColors.warning600,
                      size: 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Optional — share details about your experience',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Row(
              children: [
                AppButton(
                  label: myRating != null ? 'Update rating' : 'Submit rating',
                  isLoading: _submitting,
                  onPressed: _score == 0 ? null : _submit,
                  expand: false,
                ),
                if (myRating != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _submitting ? null : _remove,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _formOpen = false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.score, this.size = 16});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var n = 1; n <= 5; n++)
          Icon(n <= score ? Icons.star : Icons.star_border, size: size, color: AppColors.warning600),
      ],
    );
  }
}

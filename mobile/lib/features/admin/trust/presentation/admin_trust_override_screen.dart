import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../listings/data/models/trust_score.dart';
import '../application/admin_trust_providers.dart';

/// Sets or clears a manual trust-score override for one `PropertyListing`.
/// There is no dedicated single-listing trust GET endpoint, so the current
/// breakdown is shown only after the admin submits a set/clear action here —
/// both mutation endpoints return the full `TrustScoreResource`. Reachable
/// either from [AdminTrustFactorsScreen]'s manual lookup or directly from a
/// listing moderation detail screen elsewhere, so this must work standalone
/// given only the listing ID.
class AdminTrustOverrideScreen extends ConsumerStatefulWidget {
  const AdminTrustOverrideScreen({super.key, required this.listingId});

  final int listingId;

  @override
  ConsumerState<AdminTrustOverrideScreen> createState() => _AdminTrustOverrideScreenState();
}

class _AdminTrustOverrideScreenState extends ConsumerState<AdminTrustOverrideScreen> {
  final _scoreController = TextEditingController();
  final _noteController = TextEditingController();
  TrustScore? _result;
  bool _submitting = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setOverride() async {
    final score = int.tryParse(_scoreController.text.trim());
    final note = _noteController.text.trim();
    if (score == null || score < 0 || score > 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a score between 0 and 100.')));
      return;
    }
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A note is required.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminTrustRepositoryProvider)
          .setOverride(widget.listingId, overrideScore: score, note: note);
      if (mounted) {
        setState(() => _result = result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Override set.')));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _clearOverride() async {
    setState(() => _submitting = true);
    try {
      final result = await ref.read(adminTrustRepositoryProvider).clearOverride(widget.listingId);
      if (mounted) {
        setState(() => _result = result);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Override cleared.')));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trust override — listing #${widget.listingId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Override score (0-100)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(labelText: 'Note', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 8),
                  AppButton(label: 'Set override', isLoading: _submitting, onPressed: _setOverride),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Clear override',
                    variant: AppButtonVariant.outlined,
                    isLoading: _submitting,
                    onPressed: _clearOverride,
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultBreakdown(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultBreakdown extends StatelessWidget {
  const _ResultBreakdown({required this.result});

  final TrustScore result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Score: ${result.score}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 12),
            Text('(computed: ${result.computedScore})', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Text(
          result.isOverridden ? 'Currently overridden.' : 'No active override — using computed score.',
          style: const TextStyle(color: AppColors.ink700),
        ),
        const SizedBox(height: 12),
        for (final factor in result.breakdown)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factor.label ?? factor.key ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(factor.explanation, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    '${factor.pointsAwarded.toStringAsFixed(0)} / ${factor.maxPoints.toStringAsFixed(0)} points',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

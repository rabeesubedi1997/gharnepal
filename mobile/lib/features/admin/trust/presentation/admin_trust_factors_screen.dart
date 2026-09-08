import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_trust_providers.dart';
import '../data/models/trust_score_factor.dart';

/// Global tuning for the 9 fixed trust-score factors, plus a manual
/// "look up a listing" entry point into [AdminTrustOverrideScreen] — there's
/// no backend endpoint listing overridable listings, so a direct ID lookup
/// is the only discovery mechanism here.
class AdminTrustFactorsScreen extends ConsumerWidget {
  const AdminTrustFactorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factors = ref.watch(adminTrustFactorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trust score factors')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ListingLookupCard(),
          const SizedBox(height: 20),
          Text('Global factor tuning', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Changes here only affect future score recomputes — they do not retroactively '
            'change any listing\'s already-computed score.',
            style: TextStyle(color: AppColors.ink700),
          ),
          const SizedBox(height: 12),
          factors.when(
            loading: () => const Column(
              children: [
                Skeleton(height: 76, borderRadius: BorderRadius.all(Radius.circular(12))),
                SizedBox(height: 10),
                Skeleton(height: 76, borderRadius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
            error: (error, _) => ErrorState(
              message: 'Could not load trust score factors.',
              onRetry: () => ref.invalidate(adminTrustFactorsProvider),
            ),
            data: (items) => items.isEmpty
                ? const EmptyState(title: 'No factors configured.', icon: Icons.rule_outlined)
                : Column(children: [for (final f in items) _FactorRow(factor: f)]),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends ConsumerStatefulWidget {
  const _FactorRow({required this.factor});

  final TrustScoreFactor factor;

  @override
  ConsumerState<_FactorRow> createState() => _FactorRowState();
}

class _FactorRowState extends ConsumerState<_FactorRow> {
  late final _maxPointsController = TextEditingController(text: widget.factor.maxPoints.toString());
  bool _busy = false;

  @override
  void dispose() {
    _maxPointsController.dispose();
    super.dispose();
  }

  Future<void> _saveMaxPoints() async {
    final value = int.tryParse(_maxPointsController.text.trim());
    if (value == null || value < 1 || value > 100) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a number between 1 and 100.')));
        _maxPointsController.text = widget.factor.maxPoints.toString();
      }
      return;
    }
    if (value == widget.factor.maxPoints) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminTrustRepositoryProvider).updateFactor(widget.factor.id, maxPoints: value);
      ref.invalidate(adminTrustFactorsProvider);
    } catch (error) {
      _showError(error);
      if (mounted) _maxPointsController.text = widget.factor.maxPoints.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive(bool value) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminTrustRepositoryProvider).updateFactor(widget.factor.id, isActive: value);
      ref.invalidate(adminTrustFactorsProvider);
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
    final factor = widget.factor;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(factor.label, style: Theme.of(context).textTheme.titleSmall),
                ),
                Switch(value: factor.isActive, onChanged: _busy ? null : _toggleActive),
              ],
            ),
            if (factor.description != null && factor.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  factor.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                ),
              ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _maxPointsController,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max points'),
                onSubmitted: (_) => _saveMaxPoints(),
                onTapOutside: (_) => _saveMaxPoints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingLookupCard extends StatefulWidget {
  const _ListingLookupCard();

  @override
  State<_ListingLookupCard> createState() => _ListingLookupCardState();
}

class _ListingLookupCardState extends State<_ListingLookupCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go() {
    final id = int.tryParse(_controller.text.trim());
    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid listing ID.')));
      return;
    }
    context.push('/admin/trust-override/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Override a listing\'s trust score', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Look up a listing by ID to view its current breakdown and set or clear a manual override.',
              style: TextStyle(color: AppColors.ink700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Listing ID'),
                    onSubmitted: (_) => _go(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _go, child: const Text('Go')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

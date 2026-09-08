import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../application/owner_providers.dart';
import '../application/payments_providers.dart';
import '../data/models/featured_plan.dart';
import '../data/models/payment_transaction.dart';

/// Mirrors the "Feature this listing" modal on the website — purchase a
/// boost plan, then a **sandbox** checkout screen where the buyer simulates
/// their own success/failure outcome (there's no real payment gateway
/// wired up yet, see App\Domain\Payments\Services\SandboxPaymentGateway).
class FeatureListingSheet extends ConsumerStatefulWidget {
  const FeatureListingSheet({super.key, required this.listingId});

  final int listingId;

  static Future<void> show(BuildContext context, int listingId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeatureListingSheet(listingId: listingId),
    );
  }

  @override
  ConsumerState<FeatureListingSheet> createState() => _FeatureListingSheetState();
}

class _FeatureListingSheetState extends ConsumerState<FeatureListingSheet> {
  PaymentTransaction? _pending;
  bool _busy = false;

  Future<void> _purchase(String planKey) async {
    setState(() => _busy = true);
    try {
      final transaction = await ref.read(paymentsRepositoryProvider).purchase(widget.listingId, planKey);
      if (mounted) setState(() => _pending = transaction);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm({required bool success}) async {
    final transaction = _pending;
    if (transaction == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(paymentsRepositoryProvider).confirm(transaction.id, success: success);
      ref.invalidate(myPropertiesProvider);
      ref.invalidate(paymentHistoryProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Listing featured!' : 'Payment failed — no charge was made.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _pending == null ? _buildPlanPicker(context) : _buildCheckout(context),
      ),
    );
  }

  Widget _buildPlanPicker(BuildContext context) {
    final plans = ref.watch(featuredPlansProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Feature this listing', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Featured listings show a highlighted badge and rank higher in search.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
        ),
        const SizedBox(height: 16),
        plans.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Text('Could not load plans.'),
          data: (items) => Column(children: [for (final plan in items) _PlanTile(plan: plan, onTap: _purchase)]),
        ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _buildCheckout(BuildContext context) {
    final transaction = _pending!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sandbox checkout', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.warning100, borderRadius: BorderRadius.circular(8)),
          child: Text(
            'This is a sandbox environment — no real payment gateway is connected yet. '
            'Choose an outcome below to simulate what a real checkout would do.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning600),
          ),
        ),
        const SizedBox(height: 16),
        Text('${transaction.planDays}-day boost', style: Theme.of(context).textTheme.titleMedium),
        Text('Reference: ${transaction.gatewayReference}', style: Theme.of(context).textTheme.bodySmall),
        Text(
          NprFormatter.format(transaction.amount),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Simulate successful payment',
          isLoading: _busy,
          onPressed: () => _confirm(success: true),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Simulate failed payment',
          variant: AppButtonVariant.outlined,
          isLoading: _busy,
          onPressed: () => _confirm(success: false),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final FeaturedPlan plan;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(plan.label),
        subtitle: Text(NprFormatter.format(plan.price)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onTap(plan.key),
      ),
    );
  }
}

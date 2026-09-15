import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../application/owner_providers.dart';
import '../application/payments_providers.dart';
import '../data/models/checkout_instruction.dart';
import '../data/models/featured_plan.dart';
import '../data/models/payment_gateway_option.dart';
import '../data/models/payment_transaction.dart';

enum _Step { plan, gateway, checkout, result }

/// Mirrors the "Feature this listing" modal on the website: pick a boost
/// plan, then pick from whatever payment methods an admin has enabled. A
/// sandbox purchase simulates its own outcome in-app; a real gateway opens
/// the system browser to actually pay (the backend hands back one URL that
/// does the right thing — redirect or signed form-post — so this screen
/// never needs to know which); manual just shows the admin's instructions
/// and waits for them to confirm by hand.
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
  _Step _step = _Step.plan;
  String? _planKey;
  PaymentGatewayOption? _gateway;
  PaymentTransaction? _transaction;
  CheckoutInstruction? _checkout;
  bool _busy = false;

  Future<void> _purchase(PaymentGatewayOption gateway) async {
    final planKey = _planKey;
    if (planKey == null || _busy) return;

    setState(() {
      _busy = true;
      _gateway = gateway;
    });
    try {
      final result = await ref.read(paymentsRepositoryProvider).purchase(widget.listingId, planKey, gateway.id);
      if (!mounted) return;
      setState(() {
        _transaction = result.transaction;
        _checkout = result.checkout;
        _step = _Step.checkout;
      });

      final redirect = result.checkout.checkoutRedirectUrl;
      if ((result.checkout.mode == 'redirect' || result.checkout.mode == 'form_post') && redirect != null) {
        await launchUrl(Uri.parse(redirect), mode: LaunchMode.externalApplication);
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm({required bool success}) async {
    final transaction = _transaction;
    if (transaction == null) return;

    setState(() => _busy = true);
    try {
      final updated = await ref.read(paymentsRepositoryProvider).confirm(transaction.id, success: success);
      ref.invalidate(myPropertiesProvider);
      ref.invalidate(paymentHistoryProvider);
      if (mounted) {
        setState(() {
          _transaction = updated;
          _step = _Step.result;
        });
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
        child: switch (_step) {
          _Step.plan => _buildPlanPicker(context),
          _Step.gateway => _buildGatewayPicker(context),
          _Step.checkout => _buildCheckout(context),
          _Step.result => _buildResult(context),
        },
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
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
                const SizedBox(width: 8),
                const Expanded(child: Text('Could not load plans.')),
                TextButton(onPressed: () => ref.invalidate(featuredPlansProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (items) => Column(children: [
            for (final plan in items)
              _PlanTile(
                plan: plan,
                onTap: (key) => setState(() {
                  _planKey = key;
                  _step = _Step.gateway;
                }),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _buildGatewayPicker(BuildContext context) {
    final gateways = ref.watch(paymentGatewaysProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _step = _Step.plan),
              icon: const Icon(Icons.arrow_back),
              visualDensity: VisualDensity.compact,
            ),
            Text('How would you like to pay?', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        gateways.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
                const SizedBox(width: 8),
                const Expanded(child: Text('Could not load payment methods.')),
                TextButton(onPressed: () => ref.invalidate(paymentGatewaysProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (options) {
            if (options.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No payment method is currently available. Please try again later.'),
              );
            }
            return Column(
              children: [
                for (final option in options)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(option.label),
                      subtitle: option.isSandbox
                          ? const Text('Test mode', style: TextStyle(color: AppColors.accent600))
                          : null,
                      trailing: _busy && _gateway?.id == option.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => _purchase(option),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCheckout(BuildContext context) {
    final transaction = _transaction!;
    final checkout = _checkout!;
    final isSandbox = _gateway?.provider == 'sandbox';
    final needsExternalCheckout = checkout.mode == 'redirect' || checkout.mode == 'form_post';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isSandbox ? 'Sandbox checkout' : 'Checkout', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (isSandbox)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warning100, borderRadius: BorderRadius.circular(8)),
            child: Text(
              'This is a sandbox environment — no real payment gateway is connected yet. '
              'Choose an outcome below to simulate what a real checkout would do.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning600),
            ),
          )
        else if (needsExternalCheckout)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.trust100, borderRadius: BorderRadius.circular(8)),
            child: Text(
              'We opened ${_gateway?.label ?? 'your payment provider'} in your browser to complete this payment. '
              'Come back to Payment History once you\'re done — it activates automatically as soon as the payment is confirmed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.trust700),
            ),
          )
        else if (checkout.instructions != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.stone100, borderRadius: BorderRadius.circular(8)),
            child: Text(checkout.instructions!, style: Theme.of(context).textTheme.bodySmall),
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
        if (isSandbox) ...[
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
        ] else ...[
          if (needsExternalCheckout)
            AppButton(
              label: 'Reopen payment page',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                final url = checkout.checkoutRedirectUrl;
                if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Done for now',
            variant: needsExternalCheckout ? AppButtonVariant.primary : AppButtonVariant.outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final transaction = _transaction!;
    final success = transaction.status == 'completed';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          success ? Icons.check_circle : Icons.cancel,
          size: 48,
          color: success ? AppColors.success600 : AppColors.danger600,
        ),
        const SizedBox(height: 12),
        Text(
          success ? 'Listing is now featured!' : 'Payment failed — no charge was made.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        AppButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
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

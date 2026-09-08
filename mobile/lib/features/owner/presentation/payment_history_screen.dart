import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/payments_providers.dart';
import '../data/models/payment_transaction.dart';

/// Mirrors frontend/src/pages/Payments/PaymentHistory.tsx.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  static final _dateFormat = DateFormat('d MMM y');

  BadgeTone _statusTone(String status) => switch (status) {
    'completed' => BadgeTone.success,
    'pending' => BadgeTone.warning,
    'failed' => BadgeTone.danger,
    _ => BadgeTone.neutral, // refunded
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment history')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load your payment history.',
          onRetry: () => ref.invalidate(paymentHistoryProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(title: 'No payments yet', icon: Icons.receipt_long_outlined)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(paymentHistoryProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _TransactionCard(
                    transaction: items[index],
                    tone: _statusTone(items[index].status),
                    dateFormat: _dateFormat,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.tone, required this.dateFormat});

  final PaymentTransaction transaction;
  final BadgeTone tone;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final listing = transaction.listing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: listing != null
                      ? InkWell(
                          onTap: () => context.push('/listings/${listing.slug}'),
                          child: Text(
                            listing.title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(color: AppColors.link600, decoration: TextDecoration.underline),
                          ),
                        )
                      : Text('Listing removed', style: Theme.of(context).textTheme.titleSmall),
                ),
                AppBadge(label: transaction.status, tone: tone),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${transaction.planDays}-day boost · ${dateFormat.format(DateTime.parse(transaction.createdAt))} · ref ${transaction.gatewayReference}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            const SizedBox(height: 6),
            Text(
              NprFormatter.format(transaction.amount),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
            ),
          ],
        ),
      ),
    );
  }
}

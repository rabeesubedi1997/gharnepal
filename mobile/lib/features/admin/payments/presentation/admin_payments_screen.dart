import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/formatters/npr_formatter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_payments_providers.dart';
import '../data/models/admin_payment_transaction.dart';

/// Admin payments/refunds moderation screen. Mirrors the website's admin
/// Payments page: filter by status, view every transaction, refund a
/// completed one.
class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  static final _dateFormat = DateFormat('d MMM y, h:mm a');

  BadgeTone _statusTone(String status) => switch (status) {
    'completed' => BadgeTone.success,
    'pending' => BadgeTone.warning,
    'failed' => BadgeTone.danger,
    _ => BadgeTone.neutral, // refunded
  };

  Future<void> _refund(BuildContext context, WidgetRef ref, AdminPaymentTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund this payment?'),
        content: Text(
          'This marks the ${transaction.gatewayReference} transaction as refunded. '
          'It will not claw back any featured-listing boost already served.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Refund')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminPaymentsRepositoryProvider).refund(transaction.id);
      ref.invalidate(adminPaymentsListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not process the refund.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(adminPaymentsStatusFilterProvider);
    final page = ref.watch(adminPaymentsPageProvider);
    final result = ref.watch(adminPaymentsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: status,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      ..._DropdownItems.statuses,
                    ],
                    onChanged: (value) {
                      ref.read(adminPaymentsStatusFilterProvider.notifier).state = value;
                      ref.read(adminPaymentsPageProvider.notifier).state = 1;
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: result.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  6,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Skeleton(height: 96),
                  ),
                ),
              ),
              error: (error, _) => ErrorState(
                message: 'Could not load payments.',
                onRetry: () => ref.invalidate(adminPaymentsListProvider),
              ),
              data: (data) => data.items.isEmpty
                  ? const EmptyState(title: 'No payments found', icon: Icons.receipt_long_outlined)
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(adminPaymentsListProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.items.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _PaymentCard(
                          transaction: data.items[index],
                          tone: _statusTone(data.items[index].status),
                          dateFormat: _dateFormat,
                          onRefund: () => _refund(context, ref, data.items[index]),
                        ),
                      ),
                    ),
            ),
          ),
          result.maybeWhen(
            data: (data) => data.lastPage > 1
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: page > 1
                              ? () => ref.read(adminPaymentsPageProvider.notifier).state = page - 1
                              : null,
                          child: const Text('Previous'),
                        ),
                        Text('Page $page of ${data.lastPage}'),
                        TextButton(
                          onPressed: page < data.lastPage
                              ? () => ref.read(adminPaymentsPageProvider.notifier).state = page + 1
                              : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DropdownItems {
  static const statuses = [
    DropdownMenuItem(value: 'pending', child: Text('Pending')),
    DropdownMenuItem(value: 'completed', child: Text('Completed')),
    DropdownMenuItem(value: 'failed', child: Text('Failed')),
    DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
  ];
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.transaction,
    required this.tone,
    required this.dateFormat,
    required this.onRefund,
  });

  final AdminPaymentTransaction transaction;
  final BadgeTone tone;
  final DateFormat dateFormat;
  final VoidCallback onRefund;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${transaction.planKey} · ${transaction.planDays} days',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                AppBadge(label: transaction.status, tone: tone),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              NprFormatter.format(transaction.amount) + (transaction.currency != 'NPR' ? ' ${transaction.currency}' : ''),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
            ),
            const SizedBox(height: 4),
            Text(
              '${transaction.gateway} · ${transaction.gatewayReference}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            Text(
              dateFormat.format(DateTime.parse(transaction.createdAt)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            if (listing != null) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => context.push('/listings/${listing.slug}'),
                child: Text(
                  listing.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.link600, decoration: TextDecoration.underline),
                ),
              ),
            ],
            if (transaction.user != null) ...[
              const SizedBox(height: 2),
              Text(
                'By ${transaction.user!.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            ],
            if (transaction.status == 'completed') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: onRefund, child: const Text('Refund')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

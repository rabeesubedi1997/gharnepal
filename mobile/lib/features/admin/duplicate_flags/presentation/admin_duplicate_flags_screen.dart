import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/npr_formatter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_duplicate_flags_providers.dart';
import '../data/models/admin_duplicate_flag.dart';

/// Admin duplicate-flags queue: `GET /admin/duplicate-flags?status=`. Only
/// confirm/dismiss are supported — there is no merge endpoint.
class AdminDuplicateFlagsScreen extends ConsumerWidget {
  const AdminDuplicateFlagsScreen({super.key});

  BadgeTone _statusTone(String status) => switch (status) {
    'confirmed' => BadgeTone.danger,
    'dismissed' => BadgeTone.neutral,
    _ => BadgeTone.warning, // unreviewed
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(adminDuplicateFlagsListProvider);
    final page = ref.watch(adminDuplicateFlagsPageProvider);
    final status = ref.watch(adminDuplicateFlagsStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate flags')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in kAdminDuplicateFlagStatuses) DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(adminDuplicateFlagsStatusFilterProvider.notifier).state = value;
                ref.read(adminDuplicateFlagsPageProvider.notifier).state = 1;
              },
            ),
          ),
          Expanded(
            child: flagsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load duplicate flags.',
                onRetry: () => ref.invalidate(adminDuplicateFlagsListProvider),
              ),
              data: (result) => result.items.isEmpty
                  ? const EmptyState(title: 'No duplicate flags in this queue', icon: Icons.content_copy_outlined)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: result.items.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _DuplicateFlagCard(
                              flag: result.items[index],
                              statusTone: _statusTone(result.items[index].status),
                            ),
                          ),
                        ),
                        if (result.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: page > 1
                                      ? () => ref.read(adminDuplicateFlagsPageProvider.notifier).state = page - 1
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                Text('Page $page of ${result.lastPage}'),
                                TextButton(
                                  onPressed: page < result.lastPage
                                      ? () => ref.read(adminDuplicateFlagsPageProvider.notifier).state = page + 1
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateFlagCard extends ConsumerStatefulWidget {
  const _DuplicateFlagCard({required this.flag, required this.statusTone});

  final AdminDuplicateFlag flag;
  final BadgeTone statusTone;

  @override
  ConsumerState<_DuplicateFlagCard> createState() => _DuplicateFlagCardState();
}

class _DuplicateFlagCardState extends ConsumerState<_DuplicateFlagCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminDuplicateFlagsListProvider);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flag = widget.flag;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${flag.matchScore.toStringAsFixed(0)}% match',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
                  ),
                ),
                AppBadge(label: flag.status, tone: widget.statusTone),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ListingRefTile(ref: flag.listing)),
                const SizedBox(width: 10),
                const Icon(Icons.compare_arrows, color: AppColors.ink700),
                const SizedBox(width: 10),
                Expanded(child: _ListingRefTile(ref: flag.duplicateOf)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in flag.matchReasons)
                  AppBadge(label: kMatchReasonLabels[reason] ?? reason, tone: BadgeTone.trust),
              ],
            ),
            if (flag.status == 'unreviewed') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => ref.read(adminDuplicateFlagsRepositoryProvider).confirm(flag.id)),
                    child: const Text('Confirm'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => ref.read(adminDuplicateFlagsRepositoryProvider).dismiss(flag.id)),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListingRefTile extends StatelessWidget {
  const _ListingRefTile({required this.ref});

  final DuplicateFlagListingRef ref;

  @override
  Widget build(BuildContext context) {
    final slug = ref.slug;
    return InkWell(
      onTap: slug == null ? null : () => context.push('/listings/$slug'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.title ?? 'Listing removed',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: slug == null ? null : AppColors.link600,
              decoration: slug == null ? null : TextDecoration.underline,
            ),
          ),
          if (ref.price != null) ...[
            const SizedBox(height: 2),
            Text(
              NprFormatter.format(ref.price!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

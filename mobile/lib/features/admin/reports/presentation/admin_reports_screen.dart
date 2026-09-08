import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_reports_providers.dart';
import '../data/models/admin_listing_report.dart';

/// Admin reports queue: `GET /admin/reports?status=` — reports filed
/// against listings only.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  BadgeTone _statusTone(String status) => switch (status) {
    'action_taken' => BadgeTone.danger,
    'dismissed' => BadgeTone.neutral,
    'reviewed' => BadgeTone.success,
    _ => BadgeTone.warning, // open
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsListProvider);
    final page = ref.watch(adminReportsPageProvider);
    final status = ref.watch(adminReportsStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in kAdminReportStatuses) DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(adminReportsStatusFilterProvider.notifier).state = value;
                ref.read(adminReportsPageProvider.notifier).state = 1;
              },
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load reports.',
                onRetry: () => ref.invalidate(adminReportsListProvider),
              ),
              data: (result) => result.items.isEmpty
                  ? const EmptyState(title: 'No reports in this queue', icon: Icons.flag_outlined)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: result.items.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _ReportCard(
                              report: result.items[index],
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
                                      ? () => ref.read(adminReportsPageProvider.notifier).state = page - 1
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                Text('Page $page of ${result.lastPage}'),
                                TextButton(
                                  onPressed: page < result.lastPage
                                      ? () => ref.read(adminReportsPageProvider.notifier).state = page + 1
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

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report, required this.statusTone});

  final AdminListingReport report;
  final BadgeTone statusTone;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  Future<void> _resolve(String status) async {
    final note = await _promptForNote(status);
    if (note == null) return; // dialog cancelled

    setState(() => _busy = true);
    try {
      await ref
          .read(adminReportsRepositoryProvider)
          .resolve(widget.report.id, status: status, resolutionNote: note.isEmpty ? null : note);
      ref.invalidate(adminReportsListProvider);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptForNote(String status) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as ${status.replaceAll('_', ' ')}'),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Resolution note (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final listingTitle = report.listing.title;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: listingTitle != null && report.listing.id != null
                      ? InkWell(
                          onTap: () => context.push('/admin/listings/${report.listing.id}'),
                          child: Text(
                            listingTitle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.link600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(
                          listingTitle ?? 'Listing removed',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                ),
                AppBadge(label: report.status.replaceAll('_', ' '), tone: widget.statusTone),
              ],
            ),
            const SizedBox(height: 6),
            AppBadge(label: kAdminReportReasonLabels[report.reason] ?? report.reason, tone: BadgeTone.trust),
            if (report.details != null && report.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(report.details!),
            ],
            const SizedBox(height: 8),
            Text(
              'Reported by ${report.reportedBy?.name ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            if (report.resolutionNote != null && report.resolutionNote!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${report.resolutionNote}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            ],
            if (report.status == 'open') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _resolve('reviewed'),
                    child: const Text('Mark reviewed'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _resolve('dismissed'),
                    child: const Text('Dismiss'),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : () => _resolve('action_taken'),
                    child: const Text('Take action'),
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

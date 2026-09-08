import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/viewing_requests_providers.dart';
import '../data/models/viewing_request.dart';
import 'visit_verification_sheet.dart';

/// Mirrors frontend/src/pages/ViewingRequests.tsx: a tabbed "My requests" /
/// "Requests for my listings" view, since the same account can be both a
/// requester on one listing and a host on another.
class ViewingRequestsScreen extends StatelessWidget {
  const ViewingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Viewing requests'),
          bottom: const TabBar(
            tabs: [Tab(text: 'My requests'), Tab(text: 'For my listings')],
          ),
        ),
        body: const TabBarView(
          children: [_ViewingRequestsList(as: 'requester'), _ViewingRequestsList(as: 'host')],
        ),
      ),
    );
  }
}

class _ViewingRequestsList extends ConsumerWidget {
  const _ViewingRequestsList({required this.as});

  final String as;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(viewingRequestsProvider(as));

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load viewing requests.',
        onRetry: () => ref.invalidate(viewingRequestsProvider(as)),
      ),
      data: (items) => items.isEmpty
          ? EmptyState(
              title: as == 'requester' ? 'No viewing requests yet' : 'No requests for your listings',
              icon: Icons.calendar_month_outlined,
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(viewingRequestsProvider(as)),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _ViewingRequestCard(request: items[index], asHost: as == 'host'),
              ),
            ),
    );
  }
}

class _ViewingRequestCard extends ConsumerStatefulWidget {
  const _ViewingRequestCard({required this.request, required this.asHost});

  final ViewingRequest request;
  final bool asHost;

  @override
  ConsumerState<_ViewingRequestCard> createState() => _ViewingRequestCardState();
}

class _ViewingRequestCardState extends ConsumerState<_ViewingRequestCard> {
  bool _busy = false;

  static final _dateFormat = DateFormat('EEE, d MMM y · h:mm a');

  BadgeTone _statusTone(String status) => switch (status) {
    'confirmed' => BadgeTone.success,
    'completed' => BadgeTone.trust,
    'cancelled' || 'no_show' => BadgeTone.danger,
    _ => BadgeTone.warning,
  };

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(viewingRequestsProvider(widget.asHost ? 'host' : 'requester'));
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndReschedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;

    final datetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _act(
      () => ref
          .read(viewingRequestsRepositoryProvider)
          .transition(widget.request.id, action: 'reschedule', datetime: datetime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final person = widget.asHost ? request.requester : request.host;
    final canConfirm = widget.asHost && (request.status == 'requested' || request.status == 'rescheduled');
    final canComplete = widget.asHost && request.status == 'confirmed';
    final canCancel = ['requested', 'confirmed', 'rescheduled'].contains(request.status);
    final canReschedule = request.status == 'requested' || request.status == 'confirmed';
    final canVerify =
        !widget.asHost && request.status == 'completed' && request.visitVerification == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(request.listing.title, style: Theme.of(context).textTheme.titleSmall),
                ),
                AppBadge(label: request.status.replaceAll('_', ' '), tone: _statusTone(request.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _dateFormat.format(DateTime.parse(request.confirmedDatetime ?? request.proposedDatetime)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (person != null)
              Text(
                widget.asHost ? 'Requested by ${person.name}' : 'Host: ${person.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(request.notes!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (canConfirm || canComplete || canCancel || canReschedule || canVerify) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canConfirm)
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () => ref
                                  .read(viewingRequestsRepositoryProvider)
                                  .transition(request.id, action: 'confirm'),
                            ),
                      child: const Text('Confirm'),
                    ),
                  if (canComplete)
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () => ref
                                  .read(viewingRequestsRepositoryProvider)
                                  .transition(request.id, action: 'complete'),
                            ),
                      child: const Text('Mark completed'),
                    ),
                  if (canReschedule)
                    OutlinedButton(
                      onPressed: _busy ? null : _pickAndReschedule,
                      child: const Text('Reschedule'),
                    ),
                  if (canCancel)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () => ref
                                  .read(viewingRequestsRepositoryProvider)
                                  .transition(request.id, action: 'cancel'),
                            ),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger600),
                      child: const Text('Cancel'),
                    ),
                  if (canVerify)
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final submitted = await VisitVerificationSheet.show(context, request.id);
                              if (submitted == true) {
                                ref.invalidate(viewingRequestsProvider('requester'));
                              }
                            },
                      child: const Text('Leave visit feedback'),
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

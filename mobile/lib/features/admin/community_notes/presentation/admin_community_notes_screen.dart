import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_community_notes_providers.dart';
import '../data/models/admin_community_note.dart';

const _kStatusOptions = {
  'pending': 'Pending',
  'approved': 'Approved',
  'rejected': 'Rejected',
  'flagged_removed': 'Flagged / removed',
};

/// Mirrors the website's community-notes moderation queue: a status filter
/// plus a paginated (20/page) list with approve/reject actions available
/// only on `pending` notes.
class AdminCommunityNotesScreen extends ConsumerStatefulWidget {
  const AdminCommunityNotesScreen({super.key});

  @override
  ConsumerState<AdminCommunityNotesScreen> createState() => _AdminCommunityNotesScreenState();
}

class _AdminCommunityNotesScreenState extends ConsumerState<AdminCommunityNotesScreen> {
  String _status = 'pending';

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(adminCommunityNotesProvider(_status));

    return Scaffold(
      appBar: AppBar(title: const Text('Community notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _kStatusOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
          ),
          Expanded(
            child: notes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load community notes.',
                onRetry: () => ref.invalidate(adminCommunityNotesProvider(_status)),
              ),
              data: (state) => state.items.isEmpty
                  ? const EmptyState(title: 'No community notes here', icon: Icons.forum_outlined)
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(adminCommunityNotesProvider(_status)),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 300) {
                            ref.read(adminCommunityNotesProvider(_status).notifier).loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) => _CommunityNoteCard(
                            note: state.items[index],
                            status: _status,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityNoteCard extends ConsumerStatefulWidget {
  const _CommunityNoteCard({required this.note, required this.status});

  final AdminCommunityNote note;
  final String status;

  @override
  ConsumerState<_CommunityNoteCard> createState() => _CommunityNoteCardState();
}

class _CommunityNoteCardState extends ConsumerState<_CommunityNoteCard> {
  bool _busy = false;

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminCommunityNotesRepositoryProvider).approve(widget.note.id);
      ref.invalidate(adminCommunityNotesProvider(widget.status));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _RejectDialog.show(context);
    if (reason == null || reason.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminCommunityNotesRepositoryProvider).reject(widget.note.id, reason: reason);
      ref.invalidate(adminCommunityNotesProvider(widget.status));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppBadge(label: note.categoryLabel, tone: BadgeTone.neutral),
                const Spacer(),
                if (note.neighborhood != null)
                  InkWell(
                    onTap: () => context.push('/neighborhoods/${note.neighborhood!.id}'),
                    child: Text(
                      note.neighborhood!.name,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.link600, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.body),
            const SizedBox(height: 8),
            Text(
              note.submittedByName != null ? 'Submitted by ${note.submittedByName}' : 'Submitted by a deleted user',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            if (note.status == 'rejected' && note.rejectionReason != null && note.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Rejection reason: ${note.rejectionReason}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger600),
              ),
            ],
            if (note.status == 'pending') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(onPressed: _busy ? null : _approve, child: const Text('Approve')),
                  OutlinedButton(
                    onPressed: _busy ? null : _reject,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger600),
                    child: const Text('Reject'),
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

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(context: context, builder: (context) => const _RejectDialog());
  }

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'A reason is required.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject note'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 500,
        autofocus: true,
        decoration: InputDecoration(labelText: 'Reason', errorText: _error, alignLabelWithHint: true),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Reject')),
      ],
    );
  }
}

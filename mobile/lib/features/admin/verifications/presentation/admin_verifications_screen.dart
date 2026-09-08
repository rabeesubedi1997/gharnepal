import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../../../verifications/data/models/user_verification.dart' show kVerificationTypes;
import '../application/admin_verifications_providers.dart';
import '../data/models/admin_user_verification.dart';

/// Mirrors the website's admin KYC review queue — a status filter above a
/// paginated list of submission cards, each with Approve/Reject actions.
/// Visually modeled on VerificationCenterScreen for consistency with the
/// consumer-facing equivalent.
class AdminVerificationsScreen extends ConsumerWidget {
  const AdminVerificationsScreen({super.key});

  BadgeTone _statusTone(String status) => switch (status) {
    'approved' => BadgeTone.success,
    'rejected' => BadgeTone.danger,
    _ => BadgeTone.warning,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(adminVerificationsStatusProvider);
    final result = ref.watch(adminVerificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification queue')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminVerificationsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: kAdminVerificationStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                ref.read(adminVerificationsStatusProvider.notifier).state = value;
                ref.read(adminVerificationsPageProvider.notifier).state = 1;
              },
            ),
            const SizedBox(height: 16),
            result.when(
              loading: () => const Column(
                children: [
                  Skeleton(height: 90, borderRadius: BorderRadius.all(Radius.circular(12))),
                  SizedBox(height: 10),
                  Skeleton(height: 90, borderRadius: BorderRadius.all(Radius.circular(12))),
                ],
              ),
              error: (error, _) => ErrorState(
                message: 'Could not load the verification queue.',
                onRetry: () => ref.invalidate(adminVerificationsProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? const EmptyState(
                      title: 'No submissions here.',
                      icon: Icons.verified_user_outlined,
                    )
                  : Column(
                      children: [
                        for (final v in page.items)
                          _AdminVerificationCard(verification: v, statusTone: _statusTone),
                        const SizedBox(height: 8),
                        _Pager(page: page),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.page});

  final PaginatedResult<AdminUserVerification> page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: page.currentPage > 1
              ? () => ref.read(adminVerificationsPageProvider.notifier).state = page.currentPage - 1
              : null,
          child: const Text('Previous'),
        ),
        Text('Page ${page.currentPage} of ${page.lastPage}'),
        TextButton(
          onPressed: page.hasMore
              ? () => ref.read(adminVerificationsPageProvider.notifier).state = page.currentPage + 1
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _AdminVerificationCard extends ConsumerStatefulWidget {
  const _AdminVerificationCard({required this.verification, required this.statusTone});

  final AdminUserVerification verification;
  final BadgeTone Function(String) statusTone;

  @override
  ConsumerState<_AdminVerificationCard> createState() => _AdminVerificationCardState();
}

class _AdminVerificationCardState extends ConsumerState<_AdminVerificationCard> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminVerificationsRepositoryProvider).approve(widget.verification.id);
      ref.invalidate(adminVerificationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission approved.')));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminVerificationsRepositoryProvider).reject(widget.verification.id, reason.trim());
      ref.invalidate(adminVerificationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission rejected.')));
      }
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
    final v = widget.verification;
    final isPending = v.status == 'pending';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.user?.name ?? 'Unknown user', style: Theme.of(context).textTheme.titleSmall),
                      if (v.user?.email != null)
                        Text(v.user!.email, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                AppBadge(label: v.status, tone: widget.statusTone(v.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text(kVerificationTypes[v.type] ?? v.type, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            _DocumentPreview(verification: v),
            if (v.rejectionReason != null) ...[
              const SizedBox(height: 6),
              Text(v.rejectionReason!, style: const TextStyle(color: AppColors.danger600)),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Approve',
                      isLoading: _busy,
                      onPressed: _busy ? null : _approve,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      variant: AppButtonVariant.outlined,
                      isLoading: _busy,
                      onPressed: _busy ? null : _reject,
                    ),
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

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.verification});

  final AdminUserVerification verification;

  @override
  Widget build(BuildContext context) {
    final url = verification.documentUrl;
    if (url == null) {
      return const Text('No document attached.', style: TextStyle(color: AppColors.ink700));
    }

    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: verification.isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, _) => const Skeleton(height: 120),
                errorWidget: (context, _, _) => const Icon(Icons.broken_image_outlined),
              ),
            )
          : Row(
              children: const [
                Icon(Icons.picture_as_pdf_outlined, size: 32),
                SizedBox(width: 8),
                Text('View document'),
              ],
            ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject submission'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Explain why this submission is being rejected.',
          alignLabelWithHint: true,
        ),
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

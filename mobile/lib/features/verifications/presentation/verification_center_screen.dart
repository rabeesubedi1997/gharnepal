import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/verifications_providers.dart';
import '../data/models/user_verification.dart';

/// Mirrors frontend/src/pages/VerificationCenter.tsx: an upload card (type +
/// file, with a client-side 10MB pre-check matching the backend's own
/// limit) above a live-polled list of the user's own submissions.
class VerificationCenterScreen extends ConsumerWidget {
  const VerificationCenterScreen({super.key});

  static const _maxBytes = 10 * 1024 * 1024;

  BadgeTone _statusTone(String status) => switch (status) {
    'approved' => BadgeTone.success,
    'rejected' => BadgeTone.danger,
    _ => BadgeTone.warning,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifications = ref.watch(myVerificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification center')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myVerificationsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _UploadCard(),
            const SizedBox(height: 20),
            Text('Your submissions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            verifications.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load your submissions.',
                onRetry: () => ref.invalidate(myVerificationsProvider),
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(title: 'No documents submitted yet.', icon: Icons.verified_user_outlined)
                  : Column(
                      children: [for (final v in items) _VerificationTile(verification: v, statusTone: _statusTone)],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({required this.verification, required this.statusTone});

  final UserVerification verification;
  final BadgeTone Function(String) statusTone;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(verification.isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined),
        title: Text(kVerificationTypes[verification.type] ?? verification.type),
        subtitle: verification.rejectionReason != null
            ? Text(verification.rejectionReason!, style: const TextStyle(color: AppColors.danger600))
            : null,
        trailing: AppBadge(label: verification.status, tone: statusTone(verification.status)),
        onTap: verification.documentUrl != null
            ? () => launchUrl(Uri.parse(verification.documentUrl!), mode: LaunchMode.externalApplication)
            : null,
      ),
    );
  }
}

class _UploadCard extends ConsumerStatefulWidget {
  const _UploadCard();

  @override
  ConsumerState<_UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends ConsumerState<_UploadCard> {
  String _type = 'identity';
  PlatformFile? _file;
  bool _submitting = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final picked = result?.files.singleOrNull;
    if (picked == null) return;

    if (picked.size > VerificationCenterScreen._maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File must be under 10MB.')));
      }
      return;
    }
    setState(() => _file = picked);
  }

  Future<void> _submit() async {
    final file = _file;
    if (file?.path == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(verificationsRepositoryProvider).submit(type: _type, filePath: file!.path!);
      ref.invalidate(myVerificationsProvider);
      if (mounted) {
        setState(() => _file = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document submitted for review.')));
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    final isImage = file != null && ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit a document', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('JPG, PNG, or PDF — up to 10MB.'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Document type'),
              items: kVerificationTypes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            if (file != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.stone200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isImage && file.path != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(file.path!), width: 48, height: 48, fit: BoxFit.cover),
                      )
                    else
                      const Icon(Icons.picture_as_pdf_outlined, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _file = null)),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Choose file'),
              ),
            const SizedBox(height: 12),
            AppButton(label: 'Submit for review', isLoading: _submitting, onPressed: file == null ? null : _submit),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../widgets/app_button.dart';
import '../application/viewing_requests_providers.dart';

/// Post-visit feedback form — mirrors the verification form on
/// frontend/src/pages/ViewingRequests.tsx. Feeds the Trust Index (see
/// backend's `TrustScoreCalculator::recompute`, triggered on submit).
class VisitVerificationSheet extends ConsumerStatefulWidget {
  const VisitVerificationSheet({super.key, required this.viewingRequestId});

  final int viewingRequestId;

  static Future<bool?> show(BuildContext context, int viewingRequestId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => VisitVerificationSheet(viewingRequestId: viewingRequestId),
    );
  }

  @override
  ConsumerState<VisitVerificationSheet> createState() => _VisitVerificationSheetState();
}

class _VisitVerificationSheetState extends ConsumerState<VisitVerificationSheet> {
  bool _visited = true;
  bool? _matchedListing;
  bool? _priceAccurate;
  bool? _hostAttended;
  bool? _documentsShown;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(viewingRequestsRepositoryProvider)
          .submitVisitVerification(
            widget.viewingRequestId,
            visited: _visited,
            matchedListing: _matchedListing,
            priceAccurate: _priceAccurate,
            hostAttended: _hostAttended,
            documentsShown: _documentsShown,
            overallComment: _commentController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How did the visit go?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I visited this property'),
                value: _visited,
                onChanged: (value) => setState(() => _visited = value),
              ),
              _TriStateRow(
                label: 'Matched the listing description',
                value: _matchedListing,
                onChanged: (value) => setState(() => _matchedListing = value),
              ),
              _TriStateRow(
                label: 'Price was accurate',
                value: _priceAccurate,
                onChanged: (value) => setState(() => _priceAccurate = value),
              ),
              _TriStateRow(
                label: 'Host/owner attended',
                value: _hostAttended,
                onChanged: (value) => setState(() => _hostAttended = value),
              ),
              _TriStateRow(
                label: 'Ownership documents were shown',
                value: _documentsShown,
                onChanged: (value) => setState(() => _documentsShown = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Anything else? (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              AppButton(label: 'Submit feedback', isLoading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriStateRow extends StatelessWidget {
  const _TriStateRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          ToggleButtons(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
            isSelected: [value == true, value == false],
            onPressed: (index) => onChanged(index == 0 ? true : false),
            children: const [Icon(Icons.check, size: 18), Icon(Icons.close, size: 18)],
          ),
        ],
      ),
    );
  }
}

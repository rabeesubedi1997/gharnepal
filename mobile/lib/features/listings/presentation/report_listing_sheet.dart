import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../widgets/app_button.dart';
import '../application/listings_providers.dart';

/// Reason codes accepted by `ListingReportController::store`'s validation —
/// keep in sync with backend/app/Http/Controllers/Api/V1/ListingReportController.php.
const Map<String, String> _kReasonLabels = {
  'fraud': 'Fraud / scam',
  'duplicate': 'Duplicate listing',
  'sold_already': 'Already sold or rented',
  'misleading': 'Misleading information',
  'inappropriate': 'Inappropriate content',
  'other': 'Other',
};

/// Mirrors the "Report this listing" modal on frontend/src/pages/ListingDetail.tsx.
/// Pops `true` on a successful submit so the caller can show a confirmation
/// snackbar, matching [RequestViewingSheet]'s convention.
class ReportListingSheet extends ConsumerStatefulWidget {
  const ReportListingSheet({super.key, required this.listingId});

  final int listingId;

  static Future<bool?> show(BuildContext context, int listingId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportListingSheet(listingId: listingId),
    );
  }

  @override
  ConsumerState<ReportListingSheet> createState() => _ReportListingSheetState();
}

class _ReportListingSheetState extends ConsumerState<ReportListingSheet> {
  String _reason = 'misleading';
  final _detailsController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(listingsRepositoryProvider)
          .reportListing(widget.listingId, reason: _reason, details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _error = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        _submitting = false;
      });
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Report this listing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: [
                for (final entry in _kReasonLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _reason = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Any details that would help our team',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            AppButton(label: 'Submit report', isLoading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

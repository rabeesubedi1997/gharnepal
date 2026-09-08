import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../widgets/app_button.dart';
import '../application/viewing_requests_providers.dart';

/// Mirrors the "Request a viewing" modal on frontend/src/pages/ListingDetail.tsx.
class RequestViewingSheet extends ConsumerStatefulWidget {
  const RequestViewingSheet({super.key, required this.listingId});

  final int listingId;

  static Future<bool?> show(BuildContext context, int listingId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RequestViewingSheet(listingId: listingId),
    );
  }

  @override
  ConsumerState<RequestViewingSheet> createState() => _RequestViewingSheetState();
}

class _RequestViewingSheetState extends ConsumerState<RequestViewingSheet> {
  DateTime? _datetime;
  final _notesController = TextEditingController();
  bool _submitting = false;

  static final _dateFormat = DateFormat('EEE, d MMM y · h:mm a');

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDatetime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 11, minute: 0));
    if (time == null || !mounted) return;

    setState(() => _datetime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final datetime = _datetime;
    if (datetime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a date and time first.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(viewingRequestsRepositoryProvider)
          .request(listingId: widget.listingId, proposedDatetime: datetime, notes: _notesController.text.trim());
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Request a viewing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDatetime,
              icon: const Icon(Icons.event),
              label: Text(_datetime == null ? 'Choose date & time' : _dateFormat.format(_datetime!)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Send request', isLoading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../widgets/app_button.dart';
import '../application/messaging_providers.dart';

/// The "Message owner" composer, mirrors frontend/src/pages/ListingDetail.tsx's
/// modal. Starting a conversation is idempotent per (listing, buyer) pair on
/// the backend, so re-opening this on the same listing just continues the
/// existing thread.
class StartConversationSheet extends ConsumerStatefulWidget {
  const StartConversationSheet({super.key, this.listingId, this.propertyRequestId, this.title = 'Send a message'});

  final int? listingId;
  final int? propertyRequestId;
  final String title;

  /// Returns the new/existing conversation's id, or null if cancelled.
  static Future<int?> show(
    BuildContext context, {
    int? listingId,
    int? propertyRequestId,
    String title = 'Send a message',
  }) {
    assert((listingId == null) != (propertyRequestId == null));
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StartConversationSheet(
        listingId: listingId,
        propertyRequestId: propertyRequestId,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<StartConversationSheet> createState() => _StartConversationSheetState();
}

class _StartConversationSheetState extends ConsumerState<StartConversationSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() => _sending = true);
    try {
      final conversation = await ref
          .read(messagingRepositoryProvider)
          .start(listingId: widget.listingId, propertyRequestId: widget.propertyRequestId, message: message);
      if (mounted) Navigator.of(context).pop(conversation.id);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Hi, is this still available?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Send', isLoading: _sending, onPressed: _send),
          ],
        ),
      ),
    );
  }
}

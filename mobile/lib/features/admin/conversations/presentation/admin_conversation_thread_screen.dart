import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_conversations_providers.dart';
import '../data/models/admin_conversation.dart';
import '../data/models/admin_message.dart';

/// Admin thread view — reply-as-support. Polls every 4s (see
/// `adminConversationProvider`). There is no backend field marking a
/// message as "from support" — see `AdminConversation.isSupportMessage`.
class AdminConversationThreadScreen extends ConsumerStatefulWidget {
  const AdminConversationThreadScreen({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<AdminConversationThreadScreen> createState() => _AdminConversationThreadScreenState();
}

class _AdminConversationThreadScreenState extends ConsumerState<AdminConversationThreadScreen> {
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(adminConversationsRepositoryProvider).sendMessage(widget.conversationId, body);
      _bodyController.clear();
      ref.invalidate(adminConversationProvider(widget.conversationId));
      ref.invalidate(adminConversationsListProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not send. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(adminConversationProvider(widget.conversationId));

    final title = conversation.valueOrNull != null
        ? '${conversation.valueOrNull!.buyer?.name ?? 'Buyer'} ↔ ${conversation.valueOrNull!.owner?.name ?? 'Owner'}'
        : 'Conversation';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: conversation.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load this conversation.',
                onRetry: () => ref.invalidate(adminConversationProvider(widget.conversationId)),
              ),
              data: (data) => _MessageList(conversation: data),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Reply as support...', counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
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

class _MessageList extends StatelessWidget {
  const _MessageList({required this.conversation});

  final AdminConversation conversation;

  @override
  Widget build(BuildContext context) {
    if (conversation.messages.isEmpty) {
      return const Center(child: Text('No messages yet.'));
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: conversation.messages.length,
      itemBuilder: (context, index) {
        final message = conversation.messages[conversation.messages.length - 1 - index];
        return _MessageBubble(conversation: conversation, message: message);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.conversation, required this.message});

  final AdminConversation conversation;
  final AdminMessage message;

  @override
  Widget build(BuildContext context) {
    final isSupport = conversation.isSupportMessage(message);
    final isOwner = !isSupport && message.sender?.id == conversation.owner?.id;
    final isRight = isSupport || isOwner;

    final background = isSupport
        ? AppColors.accent100
        : isOwner
        ? AppColors.trust100
        : AppColors.stone100;

    final label = isSupport ? 'Support' : (message.sender?.name ?? 'Unknown');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSupport ? AppColors.accent600 : AppColors.ink700,
                fontWeight: isSupport ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
            child: Text(message.body),
          ),
        ],
      ),
    );
  }
}

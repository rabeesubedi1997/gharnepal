import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../auth/application/auth_controller.dart';
import '../application/messaging_providers.dart';
import '../data/models/conversation.dart';

/// Mirrors the conversation list in frontend/src/pages/Messages/index.tsx —
/// polls every 15s (see `conversationsProvider`).
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: FilledButton(onPressed: () => context.push('/login'), child: const Text('Log in')),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      );
    }

    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load your messages.',
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                title: 'No conversations yet',
                message: 'Messages with owners and buyers will show up here.',
                icon: Icons.forum_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(conversationsProvider),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ConversationTile(conversation: items[index]),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final coverUrl = conversation.listing?.coverImageUrl;

    return ListTile(
      onTap: () => context.push('/messages/${conversation.id}'),
      leading: CircleAvatar(
        backgroundColor: AppColors.stone200,
        backgroundImage: coverUrl != null ? CachedNetworkImageProvider(coverUrl) : null,
        child: coverUrl == null ? const Icon(Icons.home_outlined, color: AppColors.ink700) : null,
      ),
      title: Text(
        conversation.otherParticipant?.name ?? 'Ghar Nepal',
        style: TextStyle(fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500),
      ),
      subtitle: Text(conversation.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: conversation.unreadCount > 0
          ? AppBadge(label: '${conversation.unreadCount}', tone: BadgeTone.trust)
          : null,
    );
  }
}

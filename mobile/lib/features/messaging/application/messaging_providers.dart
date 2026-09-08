import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/messaging_repository.dart';
import '../data/models/conversation.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(apiClient: ref.watch(apiClientProvider));
});

/// Polls every 15s while watched, matching the website's conversation-list
/// cadence (frontend/src/lib/api/messaging.ts `useConversations`) — the
/// stopgap for not having websockets yet. `autoDispose` stops the timer as
/// soon as nothing is listening (e.g. the screen is popped). Guests get an
/// empty result with no network call — `AppBottomNav` watches this on every
/// screen (for the unread badge) and the endpoint requires auth.
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
  if (!loggedIn) return [];

  final repo = ref.watch(messagingRepositoryProvider);
  final timer = Timer(const Duration(seconds: 15), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final result = await repo.conversations();
  return result.items;
});

/// Polls every 4s while a thread is open, matching the website's
/// `useConversation` cadence. Fetching also marks the thread's messages
/// read server-side (no separate endpoint for that).
final conversationProvider = FutureProvider.autoDispose.family<Conversation, int>((ref, id) async {
  final repo = ref.watch(messagingRepositoryProvider);
  final timer = Timer(const Duration(seconds: 4), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return repo.conversation(id);
});

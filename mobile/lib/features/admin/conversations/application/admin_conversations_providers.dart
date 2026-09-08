import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_conversations_repository.dart';
import '../data/models/admin_conversation.dart';

final adminConversationsRepositoryProvider = Provider<AdminConversationsRepository>((ref) {
  return AdminConversationsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Status filter: null (all) | open | closed.
final adminConversationsStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Search query matching buyer/owner name-or-email.
final adminConversationsQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final adminConversationsPageProvider = StateProvider.autoDispose<int>((ref) => 1);

/// Polls every 15s while watched, matching the consumer conversation list's
/// cadence (see `messaging_providers.dart`).
final adminConversationsListProvider = FutureProvider.autoDispose<PaginatedResult<AdminConversation>>((ref) async {
  final status = ref.watch(adminConversationsStatusFilterProvider);
  final query = ref.watch(adminConversationsQueryProvider);
  final page = ref.watch(adminConversationsPageProvider);

  final repo = ref.watch(adminConversationsRepositoryProvider);
  final timer = Timer(const Duration(seconds: 15), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return repo.conversations(status: status, q: query.isEmpty ? null : query, page: page);
});

/// Polls every 4s while a thread is open, matching the consumer thread's
/// cadence.
final adminConversationProvider = FutureProvider.autoDispose.family<AdminConversation, int>((ref, id) async {
  final repo = ref.watch(adminConversationsRepositoryProvider);
  final timer = Timer(const Duration(seconds: 4), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return repo.conversation(id);
});

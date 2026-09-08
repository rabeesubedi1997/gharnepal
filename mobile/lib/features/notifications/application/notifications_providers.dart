import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Polls every 20s while logged in, matching the website's
/// `useNotifications` cadence — guests get an empty result with no network
/// call, since the endpoint requires auth.
final notificationsProvider = FutureProvider.autoDispose<NotificationsResult>((ref) async {
  final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
  if (!loggedIn) return NotificationsResult(items: [], unreadCount: 0);

  final timer = Timer(const Duration(seconds: 20), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(notificationsRepositoryProvider).list();
});

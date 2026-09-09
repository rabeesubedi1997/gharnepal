import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/notifications_providers.dart';
import '../data/models/app_notification.dart';

/// Mirrors the notification list behind `NotificationBell` on the website.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load notifications.',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (result) => result.items.isEmpty
            ? const EmptyState(title: 'No notifications yet', icon: Icons.notifications_none)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.separated(
                  itemCount: result.items.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _NotificationTile(notification: result.items[index]),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData get _icon => switch (notification.type) {
    'new_message' => Icons.chat_bubble_outline,
    'listing_approved' => Icons.check_circle_outline,
    'listing_rejected' => Icons.cancel_outlined,
    'listing_featured' => Icons.star_outline,
    _ => Icons.notifications_none,
  };

  void _open(BuildContext context, WidgetRef ref) {
    if (notification.isUnread) {
      ref.read(notificationsRepositoryProvider).markRead(notification.id);
      ref.invalidate(notificationsProvider);
    }
    if (notification.type == 'new_message' && notification.data['conversation_id'] != null) {
      context.push('/messages/${notification.data['conversation_id']}');
    } else if (notification.type == 'listing_rejected') {
      // The public listing endpoint only returns published listings, so a
      // rejected listing's page would 404 — send the owner to their
      // dashboard instead, matching the website's NotificationBell routing.
      context.push('/dashboard');
    } else if (notification.data['listing_slug'] != null) {
      context.push('/listings/${notification.data['listing_slug']}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => _open(context, ref),
      leading: CircleAvatar(
        backgroundColor: notification.isUnread ? AppColors.trust100 : AppColors.stone100,
        child: Icon(_icon, color: notification.isUnread ? AppColors.trust700 : AppColors.ink700),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              notification.message,
              style: TextStyle(
                fontWeight: notification.isUnread ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (notification.isUnread) ...[
            const SizedBox(width: 8),
            Semantics(label: 'Unread', child: const AppBadge(label: 'New', tone: BadgeTone.trust)),
          ],
        ],
      ),
    );
  }
}

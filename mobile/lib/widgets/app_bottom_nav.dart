import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/messaging/application/messaging_providers.dart';

/// The app's five top-level destinations. Each root screen embeds this in
/// its own `Scaffold.bottomNavigationBar` with its own index — a simple
/// push-based nav (no `IndexedStack`) since these are also independently
/// reachable via deep pushes (e.g. a listing's "Message owner" opens
/// Messages mid-stack).
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = ['/', '/search', '/messages', '/saved', '/account'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadConversations = ref.watch(conversationsProvider).valueOrNull;
    final hasUnread = unreadConversations?.any((c) => c.unreadCount > 0) ?? false;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        context.go(_paths[index]);
      },
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(
          icon: Badge(isLabelVisible: hasUnread, child: const Icon(Icons.chat_bubble_outline)),
          selectedIcon: const Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        const NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Saved',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/favorites/application/favorites_providers.dart';

/// A heart toggle reused on `PropertyCard` and Listing Detail. Guests are
/// sent to login instead of hitting the (auth-only) favorites endpoint.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.listingId, this.compact = false});

  final int listingId;

  /// Compact = a small circular overlay button (for cards); otherwise a
  /// full-size IconButton (for the Listing Detail app bar).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final isFavorited = favoriteIds.valueOrNull?.contains(listingId) ?? false;

    Future<void> handleTap() async {
      if (!isLoggedIn) {
        context.push('/login');
        return;
      }
      try {
        await ref.read(favoriteIdsProvider.notifier).toggle(listingId);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not update favorites. Please try again.')));
        }
      }
    }

    final icon = Icon(
      isFavorited ? Icons.favorite : Icons.favorite_border,
      color: isFavorited ? Colors.redAccent : (compact ? Colors.white : null),
    );

    if (!compact) {
      return IconButton(onPressed: handleTap, icon: icon, tooltip: 'Save');
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: handleTap,
        child: Padding(padding: const EdgeInsets.all(6), child: icon),
      ),
    );
  }
}

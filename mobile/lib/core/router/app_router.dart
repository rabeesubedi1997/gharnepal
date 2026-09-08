import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/favorites/presentation/saved_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/listings/presentation/listing_detail_screen.dart';
import '../../features/messaging/presentation/conversation_thread_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/property_requests/presentation/property_requests_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/viewing_requests/presentation/viewing_requests_screen.dart';

/// Routes reachable without being signed in — the same set the website
/// treats as public (see frontend/src/App.tsx: everything under `AppLayout`
/// with no `RequireAuth` wrapper). The property-requests *board* is public
/// too (posting/responding still requires login, gated at the action level
/// rather than the route). Grows in later phases as more browsing screens
/// (neighborhoods, blog, calculators, agents) are added.
bool _isPublic(String path) {
  return path == '/' ||
      path == '/search' ||
      path.startsWith('/listings/') ||
      path == '/property-requests';
}

/// Redirect logic mirrors frontend/src/components/auth/RequireAuth.tsx:
/// unresolved session -> splash; a protected route while logged out ->
/// login; signed in on an auth screen -> home. Public routes (browsing) are
/// reachable by guests, same as the website. Admin-only routes (added once
/// the admin console is built) will add one more check here
/// (`user.roles.contains('admin')`), the same flat single-tier check the
/// website uses — see the build plan's confirmed decision to treat admin as
/// one tier, not a separate "super admin" split.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final session = ref.read(authControllerProvider);
      final at = state.matchedLocation;
      final onSplash = at == '/splash';
      final onAuthScreen = at == '/login' || at == '/register';

      if (session.isLoading) return onSplash ? null : '/splash';

      final loggedOut = session.hasError || session.valueOrNull == null;

      if (loggedOut) {
        if (onSplash) return '/';
        if (onAuthScreen || _isPublic(at)) return null;
        return '/login';
      }

      return onSplash || onAuthScreen ? '/' : null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/listings/:slug',
        builder: (context, state) => ListingDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/messages', builder: (context, state) => const ConversationsScreen()),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) =>
            ConversationThreadScreen(conversationId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
      GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
      GoRoute(path: '/property-requests', builder: (context, state) => const PropertyRequestsScreen()),
      GoRoute(path: '/viewing-requests', builder: (context, state) => const ViewingRequestsScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    ],
  );
});

/// Wraps the `authControllerProvider` state as a `Listenable` so go_router
/// re-evaluates its redirect whenever the session changes (login/logout),
/// not just on navigation.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

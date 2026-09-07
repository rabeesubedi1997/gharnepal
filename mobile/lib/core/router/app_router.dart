import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/listings/presentation/listing_detail_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Routes reachable without being signed in — the same set the website
/// treats as public (see frontend/src/App.tsx: everything under `AppLayout`
/// with no `RequireAuth` wrapper). Grows in later phases as more browsing
/// screens (neighborhoods, blog, calculators, agents) are added.
bool _isPublic(String path) {
  return path == '/' || path == '/search' || path.startsWith('/listings/');
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

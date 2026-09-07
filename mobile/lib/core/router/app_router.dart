import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Redirect logic mirrors frontend/src/components/auth/RequireAuth.tsx:
/// unresolved session -> splash; guest -> login; signed in -> home. Admin-only
/// routes (added in a later phase, once the admin console is built) will add
/// one more check here (`user.roles.contains('admin')`), the same flat
/// single-tier check the website uses — see the build plan's confirmed
/// decision to treat admin as one tier, not a separate "super admin" split.
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

      if (loggedOut) return onAuthScreen ? null : '/login';

      return onSplash || onAuthScreen ? '/' : null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
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

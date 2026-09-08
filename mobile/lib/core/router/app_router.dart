import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/agencies/presentation/agencies_screen.dart';
import '../../features/agencies/presentation/agency_profile_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/blog/presentation/blog_post_detail_screen.dart';
import '../../features/blog/presentation/blog_screen.dart';
import '../../features/calculators/presentation/calculators_screen.dart';
import '../../features/favorites/presentation/saved_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/listings/presentation/listing_detail_screen.dart';
import '../../features/matching/presentation/match_preferences_screen.dart';
import '../../features/matching/presentation/match_results_screen.dart';
import '../../features/messaging/presentation/conversation_thread_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/neighborhoods/presentation/neighborhood_profile_screen.dart';
import '../../features/neighborhoods/presentation/neighborhoods_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/owner/presentation/dashboard_screen.dart';
import '../../features/owner/presentation/edit_listing_screen.dart';
import '../../features/owner/presentation/payment_history_screen.dart';
import '../../features/owner/presentation/post_property_wizard_screen.dart';
import '../../features/property_requests/presentation/property_requests_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/verifications/presentation/verification_center_screen.dart';
import '../../features/viewing_requests/presentation/viewing_requests_screen.dart';

/// Routes reachable without being signed in — the same set the website
/// treats as public (see frontend/src/App.tsx: everything under `AppLayout`
/// with no `RequireAuth` wrapper). The property-requests *board* is public
/// too (posting/responding still requires login, gated at the action level
/// rather than the route), as are calculators (guests can compute, only
/// saving requires login) and the neighborhood/agency/blog directories.
bool _isPublic(String path) {
  return path == '/' ||
      path == '/search' ||
      path.startsWith('/listings/') ||
      path == '/property-requests' ||
      path == '/calculators' ||
      path == '/neighborhoods' ||
      path.startsWith('/neighborhoods/') ||
      path == '/agencies' ||
      path.startsWith('/agencies/') ||
      path == '/blog' ||
      path.startsWith('/blog/');
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
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/post-property', builder: (context, state) => const PostPropertyWizardScreen()),
      GoRoute(
        path: '/owner/listings/:id/edit',
        builder: (context, state) => EditListingScreen(listingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/payments', builder: (context, state) => const PaymentHistoryScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/verifications', builder: (context, state) => const VerificationCenterScreen()),
      GoRoute(path: '/calculators', builder: (context, state) => const CalculatorsScreen()),
      GoRoute(path: '/match-preferences', builder: (context, state) => const MatchPreferencesScreen()),
      GoRoute(path: '/match-results', builder: (context, state) => const MatchResultsScreen()),
      GoRoute(path: '/neighborhoods', builder: (context, state) => const NeighborhoodsScreen()),
      GoRoute(
        path: '/neighborhoods/:id',
        builder: (context, state) =>
            NeighborhoodProfileScreen(neighborhoodId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/agencies', builder: (context, state) => const AgenciesScreen()),
      GoRoute(
        path: '/agencies/:slug',
        builder: (context, state) => AgencyProfileScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/blog', builder: (context, state) => const BlogScreen()),
      GoRoute(
        path: '/blog/:slug',
        builder: (context, state) => BlogPostDetailScreen(slug: state.pathParameters['slug']!),
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

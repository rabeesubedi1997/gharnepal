import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/agencies/presentation/agencies_screen.dart';
import '../../features/agencies/presentation/agency_profile_screen.dart';
import '../../features/admin/agencies/presentation/admin_agencies_screen.dart';
import '../../features/admin/advertisements/presentation/admin_advertisements_screen.dart';
import '../../features/admin/banners/presentation/admin_banners_screen.dart';
import '../../features/admin/blog/presentation/admin_blog_editor_screen.dart';
import '../../features/admin/blog/presentation/admin_blog_screen.dart';
import '../../features/admin/community_notes/presentation/admin_community_notes_screen.dart';
import '../../features/admin/conversations/presentation/admin_conversation_thread_screen.dart';
import '../../features/admin/conversations/presentation/admin_conversations_screen.dart';
import '../../features/admin/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/admin/duplicate_flags/presentation/admin_duplicate_flags_screen.dart';
import '../../features/admin/land_profiles/presentation/admin_land_profile_verify_screen.dart';
import '../../features/admin/listings/presentation/admin_listing_detail_screen.dart';
import '../../features/admin/listings/presentation/admin_listings_screen.dart';
import '../../features/admin/locations/presentation/admin_locations_screen.dart';
import '../../features/admin/neighborhood_scores/presentation/admin_neighborhood_scores_screen.dart';
import '../../features/admin/payments/presentation/admin_payments_screen.dart';
import '../../features/admin/ratings/presentation/admin_ratings_screen.dart';
import '../../features/admin/reports/presentation/admin_reports_screen.dart';
import '../../features/admin/seo/presentation/admin_seo_page_editor_screen.dart';
import '../../features/admin/seo/presentation/admin_seo_screen.dart';
import '../../features/admin/trust/presentation/admin_trust_factors_screen.dart';
import '../../features/admin/trust/presentation/admin_trust_override_screen.dart';
import '../../features/admin/users/presentation/admin_users_screen.dart';
import '../../features/admin/verifications/presentation/admin_verifications_screen.dart';
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
/// reachable by guests, same as the website. Admin routes additionally
/// require `user.isAdmin` — the same flat single-tier check the backend's
/// `EnsureUserIsAdmin` middleware uses (see the build plan's confirmed
/// decision to treat admin as one tier, not a separate "super admin"
/// split); a non-admin hitting `/admin/*` is bounced to home exactly like
/// the website's own `RequireAuth adminOnly` behavior.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final session = ref.read(authControllerProvider);
      final at = state.matchedLocation;
      final onSplash = at == '/splash';
      final onAuthScreen = at == '/login' || at == '/register';
      final isAdminRoute = at == '/admin' || at.startsWith('/admin/');

      if (session.isLoading) return onSplash ? null : '/splash';

      final user = session.valueOrNull;
      final loggedOut = session.hasError || user == null;

      if (loggedOut) {
        if (onSplash) return '/';
        if (onAuthScreen || _isPublic(at)) return null;
        return '/login';
      }

      if (isAdminRoute && !user.isAdmin) return '/';

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

      // Admin console — every route below is additionally gated on
      // `user.isAdmin` in the redirect above. See AdminDrawer for the full
      // nav; only the dashboard carries the drawer, every other screen owns
      // its own AppBar/back button.
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users', builder: (context, state) => const AdminUsersScreen()),
      GoRoute(path: '/admin/agencies', builder: (context, state) => const AdminAgenciesScreen()),
      GoRoute(path: '/admin/listings', builder: (context, state) => const AdminListingsScreen()),
      GoRoute(
        path: '/admin/listings/:id',
        builder: (context, state) =>
            AdminListingDetailScreen(propertyListingId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/reports', builder: (context, state) => const AdminReportsScreen()),
      GoRoute(path: '/admin/duplicate-flags', builder: (context, state) => const AdminDuplicateFlagsScreen()),
      GoRoute(path: '/admin/verifications', builder: (context, state) => const AdminVerificationsScreen()),
      GoRoute(path: '/admin/trust-factors', builder: (context, state) => const AdminTrustFactorsScreen()),
      GoRoute(
        path: '/admin/trust-override/:listingId',
        builder: (context, state) =>
            AdminTrustOverrideScreen(listingId: int.parse(state.pathParameters['listingId']!)),
      ),
      GoRoute(
        path: '/admin/land-profiles/:propertyId',
        builder: (context, state) =>
            AdminLandProfileVerifyScreen(propertyId: int.parse(state.pathParameters['propertyId']!)),
      ),
      GoRoute(path: '/admin/locations', builder: (context, state) => const AdminLocationsScreen()),
      GoRoute(
        path: '/admin/neighborhood-scores',
        builder: (context, state) => const AdminNeighborhoodScoresScreen(),
      ),
      GoRoute(path: '/admin/community-notes', builder: (context, state) => const AdminCommunityNotesScreen()),
      GoRoute(path: '/admin/ratings', builder: (context, state) => const AdminRatingsScreen()),
      GoRoute(path: '/admin/payments', builder: (context, state) => const AdminPaymentsScreen()),
      GoRoute(path: '/admin/conversations', builder: (context, state) => const AdminConversationsScreen()),
      GoRoute(
        path: '/admin/conversations/:id',
        builder: (context, state) =>
            AdminConversationThreadScreen(conversationId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/banners', builder: (context, state) => const AdminBannersScreen()),
      GoRoute(path: '/admin/advertisements', builder: (context, state) => const AdminAdvertisementsScreen()),
      GoRoute(path: '/admin/blog', builder: (context, state) => const AdminBlogScreen()),
      GoRoute(path: '/admin/blog/new', builder: (context, state) => const AdminBlogEditorScreen()),
      GoRoute(
        path: '/admin/blog/:id/edit',
        builder: (context, state) => AdminBlogEditorScreen(postId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/seo', builder: (context, state) => const AdminSeoScreen()),
      GoRoute(
        path: '/admin/seo/:key',
        builder: (context, state) => AdminSeoPageEditorScreen(pageKey: state.pathParameters['key']!),
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../branding/application/branding_providers.dart';

/// Shared nav for the whole admin console — every top-level admin section
/// is reachable from here, mirroring the grouped sidebar in
/// frontend/src/pages/admin/AdminLayout.tsx. Only attached to
/// [AdminDashboardScreen] (the hub reached from Account → Admin console);
/// every other admin screen gets its own back button from go_router and the
/// admin can return to the dashboard to jump elsewhere via this drawer
/// again — avoids retrofitting a persistent shell onto 18 independently
/// built screens, each of which already owns its own Scaffold/AppBar.
class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(brandingProvider).valueOrNull;
    final logoUrl = branding?.logoUrl;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.trust700),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const _AdminLogoFallback(),
                          )
                        : const _AdminLogoFallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branding?.siteName ?? 'Ghar Nepal',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'Admin console',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _tile(context, Icons.dashboard_outlined, 'Dashboard', '/admin'),
            const _SectionHeader('Moderation'),
            _tile(context, Icons.home_work_outlined, 'Listings', '/admin/listings'),
            _tile(context, Icons.flag_outlined, 'Reports', '/admin/reports'),
            _tile(context, Icons.copy_all_outlined, 'Duplicate flags', '/admin/duplicate-flags'),
            _tile(context, Icons.verified_user_outlined, 'Verification queue', '/admin/verifications'),
            _tile(context, Icons.forum_outlined, 'Community notes', '/admin/community-notes'),
            _tile(context, Icons.star_border, 'Ratings', '/admin/ratings'),
            _tile(context, Icons.gpp_maybe_outlined, 'Security', '/admin/security'),
            const _SectionHeader('Trust & locations'),
            _tile(context, Icons.shield_outlined, 'Trust score factors', '/admin/trust-factors'),
            _tile(context, Icons.map_outlined, 'Locations', '/admin/locations'),
            _tile(context, Icons.insights_outlined, 'Neighborhood scores', '/admin/neighborhood-scores'),
            _tile(context, Icons.list_alt_outlined, 'Amenities', '/admin/amenities'),
            const _SectionHeader('Users & agencies'),
            _tile(context, Icons.people_outline, 'Users', '/admin/users'),
            _tile(context, Icons.business_outlined, 'Agencies', '/admin/agencies'),
            const _SectionHeader('Communication & finance'),
            _tile(context, Icons.chat_bubble_outline, 'Conversations', '/admin/conversations'),
            _tile(context, Icons.receipt_long_outlined, 'Payments', '/admin/payments'),
            _tile(context, Icons.credit_card_outlined, 'Payment gateways', '/admin/payment-gateways'),
            const _SectionHeader('Content'),
            _tile(context, Icons.view_carousel_outlined, 'Banners', '/admin/banners'),
            _tile(context, Icons.ad_units_outlined, 'Advertisements', '/admin/advertisements'),
            _tile(context, Icons.newspaper_outlined, 'Blog', '/admin/blog'),
            _tile(context, Icons.search_outlined, 'SEO pages', '/admin/seo'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back to app'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String path) {
    final isCurrent = GoRouterState.of(context).matchedLocation == path;
    return ListTile(
      leading: Icon(icon, color: isCurrent ? AppColors.trust700 : null),
      title: Text(label, style: isCurrent ? const TextStyle(fontWeight: FontWeight.w700) : null),
      selected: isCurrent,
      onTap: () {
        Navigator.of(context).pop();
        if (!isCurrent) context.push(path);
      },
    );
  }
}

class _AdminLogoFallback extends StatelessWidget {
  const _AdminLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: Colors.white.withValues(alpha: 0.15),
      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.ink700, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

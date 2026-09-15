import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/property_card.dart';
import '../../../widgets/skeleton.dart';
import '../../auth/application/auth_controller.dart';
import '../../listings/application/listings_providers.dart';
import '../../listings/data/models/search_filters.dart';
import '../../locations/application/locations_providers.dart';
import '../../locations/data/municipality.dart';
import '../../marketing/application/marketing_providers.dart';
import '../../marketing/data/banner.dart';
import '../../neighborhoods/application/neighborhoods_providers.dart';
import '../../neighborhoods/data/models/neighborhood_summary.dart';
import '../../notifications/application/notifications_providers.dart';
import '../../platform_stats/application/platform_stats_providers.dart';
import '../../platform_stats/data/models/platform_stats.dart';
import '../../saved_searches/application/saved_searches_providers.dart';

/// The real Home screen, rebuilt to match the "Alpine Sanctuary" mockup
/// already live on web (`frontend/src/pages/Home.tsx`): hero search, popular
/// hotspots, an alert-signup banner, the banner carousel, featured listings,
/// a "browse by city" grid, and a real trust/transparency strip. The web
/// page's install-app section has no native equivalent (nothing to
/// "install") and is correctly omitted here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Live preview of what the hero card below is currently set to — never a
  // static "newest nationwide" query, or picking a city there would
  // visibly do nothing to the very next thing on the page (Featured &
  // Verified Listings). Kept here, one level up from `_HeroSearchCard`, so
  // both it and the featured-listings query below share the same filters.
  SearchFilters _heroFilters = const SearchFilters(sort: 'newest');

  void _openSearch({SearchFilters? filters}) {
    ref.read(searchFiltersProvider.notifier).state = filters ?? const SearchFilters();
    context.push('/search');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final banners = ref.watch(bannersProvider);
    final municipalities = ref.watch(municipalitiesProvider);
    final neighborhoods = ref.watch(neighborhoodsListProvider);
    final platformStats = ref.watch(platformStatsProvider);
    final featured = ref.watch(searchResultsProvider(_heroFilters));
    final heroCityName = _heroFilters.municipalityId == null
        ? null
        : municipalities.valueOrNull?.where((m) => m.id == _heroFilters.municipalityId).firstOrNull?.name;
    final unreadNotifications = ref.watch(notificationsProvider).valueOrNull?.unreadCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghar Nepal'),
        actions: [
          if (user != null)
            IconButton(
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text('$unreadNotifications'),
                child: const Icon(Icons.notifications_none),
              ),
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
          IconButton(
            icon: Icon(user != null ? Icons.person_outline : Icons.login),
            tooltip: user != null ? 'Account' : 'Log in',
            onPressed: () => context.push(user != null ? '/account' : '/login'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(municipalitiesProvider);
          ref.invalidate(neighborhoodsListProvider);
          ref.invalidate(platformStatsProvider);
          ref.invalidate(searchResultsProvider(_heroFilters));
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _HeroSearchCard(
                municipalities: municipalities.valueOrNull ?? const [],
                publishedListings: platformStats.valueOrNull?.publishedListings,
                onSearch: (filters) => _openSearch(filters: filters),
                onFilterChanged: (filters) => setState(() => _heroFilters = filters),
              ),
            ),
            neighborhoods.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => _HotspotsRow(neighborhoods: items),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AlertSignupBanner(
                municipalities: municipalities.valueOrNull ?? const [],
                activeAlertSubscriptions: platformStats.valueOrNull?.activeAlertSubscriptions,
                isLoggedIn: user != null,
              ),
            ),
            const SizedBox(height: 20),
            banners.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Skeleton(height: 160, borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => items.isEmpty ? const SizedBox.shrink() : _BannerCarousel(banners: items),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FeaturedListings(
                state: featured,
                cityName: heroCityName,
                onRetry: () => ref.invalidate(searchResultsProvider(_heroFilters)),
                onTapListing: (slug) => context.push('/listings/$slug'),
                onViewAll: () => context.push('/search'),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Explore Nepal by Region & Valley', style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Neighborhood prices, school catchments, and infrastructure growth corridors.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            ),
            const SizedBox(height: 12),
            municipalities.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              ),
              error: (error, _) => ErrorState(
                message: 'Could not load cities.',
                onRetry: () => ref.invalidate(municipalitiesProvider),
              ),
              data: (cities) => cities.isEmpty
                  ? const EmptyState(title: 'No cities yet', icon: Icons.location_city_outlined)
                  : _CityGrid(
                      cities: cities,
                      onTap: (city) => _openSearch(filters: SearchFilters(municipalityId: city.id)),
                    ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TrustStrip(stats: platformStats.valueOrNull),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Explore', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            const _ExploreRow(),
          ],
        ),
      ),
    );
  }
}

/// Purpose tabs (Buy/Rent/Commercial/Land) + a city picker + a "Search
/// {N}+ Properties" button — the mobile-appropriate condensed form of the
/// web hero search (budget band + unit toggle live in the Search page's own
/// filter sheet on mobile rather than being duplicated here).
class _HeroSearchCard extends StatefulWidget {
  const _HeroSearchCard({
    required this.municipalities,
    required this.publishedListings,
    required this.onSearch,
    required this.onFilterChanged,
  });

  final List<Municipality> municipalities;
  final int? publishedListings;
  final ValueChanged<SearchFilters> onSearch;
  /// Fired immediately on every tab/city change (not just on submit) so the
  /// Featured & Verified Listings preview further down the page stays in
  /// sync with what's picked here — see `_HomeScreenState._heroFilters`.
  final ValueChanged<SearchFilters> onFilterChanged;

  @override
  State<_HeroSearchCard> createState() => _HeroSearchCardState();
}

class _HeroSearchCardState extends State<_HeroSearchCard> {
  static const _tabs = [
    (key: 'buy', label: 'For Sale'),
    (key: 'rent', label: 'For Rent'),
    (key: 'commercial', label: 'Commercial'),
    (key: 'land', label: 'Land / Plots'),
  ];

  String _tab = 'buy';
  int? _municipalityId;

  SearchFilters get _filters => switch (_tab) {
    'buy' => SearchFilters(purpose: 'sale', municipalityId: _municipalityId),
    'rent' => SearchFilters(purpose: 'rent', municipalityId: _municipalityId),
    'commercial' => SearchFilters(propertyType: 'commercial', municipalityId: _municipalityId),
    'land' => SearchFilters(propertyType: 'land', municipalityId: _municipalityId),
    _ => SearchFilters(municipalityId: _municipalityId),
  };

  @override
  void initState() {
    super.initState();
    // Report the (empty) starting filters up front too, not just on the
    // first change — otherwise the parent's featured-listings query starts
    // life out of sync with what this card actually shows.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFilterChanged(_filters));
  }

  void _updateTab(String tab) {
    setState(() => _tab = tab);
    widget.onFilterChanged(_filters);
  }

  void _updateMunicipality(int? id) {
    setState(() => _municipalityId = id);
    widget.onFilterChanged(_filters);
  }

  void _submit() => widget.onSearch(_filters);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tabs
                  .map(
                    (tab) => ChoiceChip(
                      label: Text(tab.label),
                      selected: _tab == tab.key,
                      onSelected: (_) => _updateTab(tab.key),
                      selectedColor: AppColors.trust700,
                      labelStyle: TextStyle(
                        color: _tab == tab.key ? Colors.white : AppColors.ink700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: _municipalityId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'City or neighborhood', isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Kathmandu Valley (All)')),
                for (final city in widget.municipalities)
                  DropdownMenuItem<int?>(value: city.id, child: Text(city.name)),
              ],
              onChanged: _updateMunicipality,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: widget.publishedListings != null
                  ? 'Search ${formatCompactCount(widget.publishedListings!)}+ Properties'
                  : 'Search Properties',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Real top-listing-count neighborhoods — renders nothing until at least
/// one neighborhood has a published listing, rather than padding the row
/// with empty places.
class _HotspotsRow extends StatelessWidget {
  const _HotspotsRow({required this.neighborhoods});

  final List<NeighborhoodSummary> neighborhoods;

  @override
  Widget build(BuildContext context) {
    final hotspots = [...neighborhoods].where((n) => n.activeListingsCount > 0).toList()
      ..sort((a, b) => b.activeListingsCount.compareTo(a.activeListingsCount));
    final top = hotspots.take(5).toList();

    if (top.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Popular hotspots:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700, fontWeight: FontWeight.w600),
          ),
          for (final n in top)
            ActionChip(
              label: Text(n.name),
              onPressed: () => context.push('/neighborhoods/${n.id}'),
              backgroundColor: AppColors.trust100,
              labelStyle: const TextStyle(color: AppColors.trust700, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

/// "Instant & Daily Property Alerts" — creates a real `SavedSearch` on the
/// visitor's own account (same alert pipeline WhatsApp/email/push already
/// use), not a fake unauthenticated capture form.
class _AlertSignupBanner extends ConsumerStatefulWidget {
  const _AlertSignupBanner({
    required this.municipalities,
    required this.activeAlertSubscriptions,
    required this.isLoggedIn,
  });

  final List<Municipality> municipalities;
  final int? activeAlertSubscriptions;
  final bool isLoggedIn;

  @override
  ConsumerState<_AlertSignupBanner> createState() => _AlertSignupBannerState();
}

class _AlertSignupBannerState extends ConsumerState<_AlertSignupBanner> {
  int? _municipalityId;
  bool _submitting = false;
  bool _done = false;

  Future<void> _enableAlerts() async {
    if (!widget.isLoggedIn) {
      context.push('/login');
      return;
    }
    setState(() => _submitting = true);
    try {
      final municipality = widget.municipalities.where((m) => m.id == _municipalityId).firstOrNull;
      await ref
          .read(savedSearchesRepositoryProvider)
          .create(
            name: municipality != null ? 'New listings in ${municipality.name}' : 'New listings, anywhere',
            filters: SearchFilters(municipalityId: _municipalityId),
          );
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUTOMATED REAL-TIME PIPELINE',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Instant & Daily Property Alerts',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Get notified via WhatsApp, email, and push the moment a matching listing appears in your chosen city.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (_done)
            Text(
              'Alerts enabled — manage frequency any time from your dashboard.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            )
          else ...[
            DropdownButtonFormField<int?>(
              initialValue: _municipalityId,
              isExpanded: true,
              dropdownColor: AppColors.ink900,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: const TextStyle(color: Colors.white70),
                floatingLabelStyle: const TextStyle(color: Colors.white),
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white70, width: 1.5),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Any city', style: TextStyle(color: Colors.white))),
                for (final city in widget.municipalities)
                  DropdownMenuItem<int?>(value: city.id, child: Text(city.name, style: const TextStyle(color: Colors.white))),
              ],
              onChanged: (value) => setState(() => _municipalityId = value),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: widget.isLoggedIn ? 'Enable alerts' : 'Log in to enable',
              isLoading: _submitting,
              onPressed: _enableAlerts,
            ),
          ],
          if ((widget.activeAlertSubscriptions ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Zero-spam policy · ${formatCompactCount(widget.activeAlertSubscriptions!)} active alert subscriptions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live preview of what the hero card above is currently set to — never a
/// static "newest nationwide" list, or picking a city there would visibly
/// do nothing to the very next thing on the page. See `_HomeScreenState`.
class _FeaturedListings extends StatelessWidget {
  const _FeaturedListings({
    required this.state,
    required this.cityName,
    required this.onRetry,
    required this.onTapListing,
    required this.onViewAll,
  });

  final AsyncValue<SearchResultsState> state;
  final String? cityName;
  final VoidCallback onRetry;
  final ValueChanged<String> onTapListing;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
      error: (error, _) => ErrorState(message: "Couldn't load listings right now.", onRetry: onRetry),
      data: (data) {
        final listings = data.items.take(6).toList();
        if (listings.isEmpty) {
          return cityName == null
              ? const SizedBox.shrink()
              : EmptyState(
                  title: 'No listings in $cityName yet',
                  message: 'Try another city, or check back soon.',
                  icon: Icons.search_off,
                );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cityName == null ? 'Featured & Verified Listings' : 'Featured & Verified Listings in $cityName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: onViewAll, child: const Text('View all →')),
              ],
            ),
            Text(
              'Authentic land ownership documents, and clear title deed histories.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: listings.length,
                separatorBuilder: (context, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return SizedBox(
                    width: 220,
                    child: PropertyCard(listing: listing, onTap: () => onTapListing(listing.slug)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 4 real stat tiles + a live per-city median land-price snapshot — every
/// figure a genuine count from `GET /platform-stats`, never a marketing
/// placeholder.
class _TrustStrip extends StatelessWidget {
  const _TrustStrip({required this.stats});

  final PlatformStats? stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (Icons.apartment_outlined, 'Published listings', stats?.publishedListings.toString()),
      (Icons.verified_user_outlined, 'Verified agencies', stats?.verifiedAgencies.toString()),
      (Icons.groups_outlined, 'Phone-verified owners', stats != null ? '${stats!.phoneVerifiedOwnerPct}%' : null),
      (Icons.location_city_outlined, 'Cities covered', stats?.citiesCovered.toString()),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.stone200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NEPAL'S BENCHMARK REAL ESTATE REGISTRY",
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.trust700, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Built for Transparency', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Every figure below is a live count from listings and accounts on this platform right now.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.4,
            children: [
              for (final tile in tiles)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.trust100, borderRadius: BorderRadius.circular(8)),
                      child: Icon(tile.$1, size: 18, color: AppColors.trust700),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tile.$3 != null
                              ? Text(
                                  tile.$3!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                )
                              : const Skeleton(width: 40, height: 22),
                          Text(
                            tile.$2,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (stats != null && stats!.landPricePerAanaByCity.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'MEDIAN LAND PRICE BY CITY (NPR / AANA)',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.ink700, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            for (final row in stats!.landPricePerAanaByCity) _LandPriceBar(row: row, stats: stats!),
          ],
        ],
      ),
    );
  }
}

class _LandPriceBar extends StatelessWidget {
  const _LandPriceBar({required this.row, required this.stats});

  final LandPriceByCity row;
  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final max = stats.landPricePerAanaByCity.map((r) => r.medianPricePerAana).reduce((a, b) => a > b ? a : b);
    final fraction = max > 0 ? (row.medianPricePerAana / max).clamp(0.06, 1.0) : 0.06;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              row.municipality,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 12,
                backgroundColor: AppColors.stone200,
                color: AppColors.accent500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            NprFormatter.formatCompact(row.medianPricePerAana),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Public-discovery shortcuts guests can reach without logging in —
/// neighborhoods/agencies/blog/calculators all have guest-accessible
/// backend endpoints (see `_isPublic` in app_router.dart).
class _ExploreRow extends StatelessWidget {
  const _ExploreRow();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.location_city_outlined, 'Neighborhoods', '/neighborhoods'),
      (Icons.business_outlined, 'Agents & agencies', '/agencies'),
      (Icons.calculate_outlined, 'Calculators', '/calculators'),
      (Icons.newspaper_outlined, 'Blog', '/blog'),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (icon, label, path) = items[index];
          return SizedBox(
            width: 96,
            child: Material(
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push(path),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.trust700),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});

  final List<AppBanner> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (page) => setState(() => _page = page),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                              ),
                            ),
                            if (banner.subtitle != null)
                              Text(
                                banner.subtitle!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _page ? AppColors.trust700 : AppColors.stone200,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CityGrid extends StatelessWidget {
  const _CityGrid({required this.cities, required this.onTap});

  final List<Municipality> cities;
  final ValueChanged<Municipality> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cities.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final city = cities[index];
          return _CityCard(city: city, onTap: () => onTap(city));
        },
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city, required this.onTap});

  final Municipality city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.stone200,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (city.imageUrl != null)
              CachedNetworkImage(imageUrl: city.imageUrl!, fit: BoxFit.cover)
            else
              const Center(child: Icon(Icons.location_city, size: 32, color: AppColors.ink700)),
            if (city.imageUrl != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.55)],
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: city.imageUrl != null ? Colors.white : AppColors.ink900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${city.wardCount} wards',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: city.imageUrl != null ? Colors.white70 : AppColors.ink700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

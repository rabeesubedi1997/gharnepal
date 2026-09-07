import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/skeleton.dart';
import '../../auth/application/auth_controller.dart';
import '../../listings/data/models/search_filters.dart';
import '../../listings/application/listings_providers.dart';
import '../../locations/application/locations_providers.dart';
import '../../locations/data/municipality.dart';
import '../../marketing/application/marketing_providers.dart';
import '../../marketing/data/banner.dart';

/// The real Home screen: banner carousel, hero search entry, and a
/// "browse by city" grid — mirroring frontend/src/pages/Home.tsx.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openSearch(BuildContext context, WidgetRef ref, {SearchFilters? filters}) {
    ref.read(searchFiltersProvider.notifier).state = filters ?? const SearchFilters();
    context.push('/search');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final banners = ref.watch(bannersProvider);
    final municipalities = ref.watch(municipalitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghar Nepal'),
        actions: [
          IconButton(
            icon: Icon(user != null ? Icons.person_outline : Icons.login),
            tooltip: user != null ? 'Account' : 'Log in',
            onPressed: () {
              if (user == null) {
                context.push('/login');
              } else {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(municipalitiesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _SearchEntry(onTap: () => _openSearch(context, ref)),
            ),
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
              child: Text('Browse by city', style: Theme.of(context).textTheme.titleLarge),
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
                      onTap: (city) => _openSearch(
                        context,
                        ref,
                        filters: SearchFilters(municipalityId: city.id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.stone200),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.ink700),
              const SizedBox(width: 12),
              Text(
                'Search houses, land, rooms...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink700),
              ),
            ],
          ),
        ),
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

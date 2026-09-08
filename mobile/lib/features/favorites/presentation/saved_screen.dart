import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/property_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../listings/application/listings_providers.dart' show searchFiltersProvider;
import '../../listings/data/models/search_filters.dart';
import '../../saved_searches/application/saved_searches_providers.dart';
import '../../saved_searches/data/models/saved_search.dart';
import '../application/favorites_providers.dart';

/// Combines Favorites and Saved Searches under one "Saved" destination —
/// mirrors frontend/src/pages/Saved.tsx plus the saved-searches section
/// surfaced from the owner Dashboard on the website.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved')),
        body: Center(
          child: FilledButton(onPressed: () => context.push('/login'), child: const Text('Log in')),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
          bottom: const TabBar(tabs: [Tab(text: 'Favorites'), Tab(text: 'Saved searches')]),
        ),
        body: const TabBarView(children: [_FavoritesTab(), _SavedSearchesTab()]),
        bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);

    return favorites.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load your favorites.',
        onRetry: () => ref.invalidate(favoritesListProvider),
      ),
      data: (state) => state.items.isEmpty
          ? const EmptyState(
              title: 'No favorites yet',
              message: 'Tap the heart on any listing to save it here.',
              icon: Icons.favorite_border,
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(favoritesListProvider),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels > notification.metrics.maxScrollExtent - 300) {
                    ref.read(favoritesListProvider.notifier).loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final listing = state.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PropertyCard(
                        listing: listing,
                        onTap: () => context.push('/listings/${listing.slug}'),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _SavedSearchesTab extends ConsumerWidget {
  const _SavedSearchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSearches = ref.watch(savedSearchesProvider);

    return savedSearches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load your saved searches.',
        onRetry: () => ref.invalidate(savedSearchesProvider),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(
              title: 'No saved searches yet',
              message: 'Save a search from the filter bar to get alerts on new matches.',
              icon: Icons.bookmark_border,
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(savedSearchesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _SavedSearchTile(savedSearch: items[index]),
              ),
            ),
    );
  }
}

class _SavedSearchTile extends ConsumerWidget {
  const _SavedSearchTile({required this.savedSearch});

  final SavedSearch savedSearch;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(savedSearchesRepositoryProvider).delete(savedSearch.id);
      ref.invalidate(savedSearchesProvider);
    } catch (error) {
      if (context.mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(savedSearch.name),
        subtitle: Text(_describe(savedSearch.filters)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger600),
          onPressed: () => _delete(context, ref),
        ),
        onTap: () {
          ref.read(searchFiltersProvider.notifier).state = savedSearch.filters;
          context.push('/search');
        },
      ),
    );
  }

  String _describe(SearchFilters filters) {
    final parts = <String>[
      if (filters.purpose != null) filters.purpose == 'rent' ? 'Rent' : 'Buy',
      if (filters.propertyType != null) filters.propertyType!,
      if (filters.minPrice != null || filters.maxPrice != null)
        'Rs ${filters.minPrice?.toStringAsFixed(0) ?? '0'}–${filters.maxPrice?.toStringAsFixed(0) ?? 'any'}',
      if (filters.bedroomsMin != null) '${filters.bedroomsMin}+ bed',
    ];
    return parts.isEmpty ? 'All listings' : parts.join(' · ');
  }
}

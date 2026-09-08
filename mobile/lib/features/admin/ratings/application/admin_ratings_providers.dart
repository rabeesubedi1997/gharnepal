import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_ratings_repository.dart';
import '../data/models/rating.dart';

final adminRatingsRepositoryProvider = Provider<AdminRatingsRepository>((ref) {
  return AdminRatingsRepository(apiClient: ref.watch(apiClientProvider));
});

class AdminRatingsState {
  AdminRatingsState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
    this.isLoadingMore = false,
  });

  final List<Rating> items;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoadingMore;

  AdminRatingsState copyWith({List<Rating>? items, int? page, bool? hasMore, bool? isLoadingMore}) {
    return AdminRatingsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Loads the first page for a given `status` filter on `build` (`'all'`
/// means the query param is omitted), and appends further pages via
/// [loadMore] — same shape as `SearchResultsController`. Unlike community
/// notes, hide/unhide responses come back with relations intact, so
/// [updateItem] merges a mutation result in place instead of refetching.
class AdminRatingsController extends FamilyAsyncNotifier<AdminRatingsState, String> {
  String? get _statusParam => arg == 'all' ? null : arg;

  @override
  Future<AdminRatingsState> build(String status) async {
    final result = await ref.read(adminRatingsRepositoryProvider).list(status: _statusParam, page: 1);
    return AdminRatingsState(
      items: result.items,
      page: result.currentPage,
      hasMore: result.hasMore,
      total: result.total,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await ref.read(adminRatingsRepositoryProvider).list(status: _statusParam, page: current.page + 1);
    state = AsyncData(
      AdminRatingsState(
        items: [...current.items, ...result.items],
        page: result.currentPage,
        hasMore: result.hasMore,
        total: result.total,
      ),
    );
  }

  void updateItem(Rating updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(items: [for (final item in current.items) if (item.id == updated.id) updated else item]),
    );
  }
}

final adminRatingsProvider = AsyncNotifierProvider.family<AdminRatingsController, AdminRatingsState, String>(
  AdminRatingsController.new,
);

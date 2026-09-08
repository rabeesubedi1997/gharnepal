import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_community_notes_repository.dart';
import '../data/models/admin_community_note.dart';

final adminCommunityNotesRepositoryProvider = Provider<AdminCommunityNotesRepository>((ref) {
  return AdminCommunityNotesRepository(apiClient: ref.watch(apiClientProvider));
});

class AdminCommunityNotesState {
  AdminCommunityNotesState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
    this.isLoadingMore = false,
  });

  final List<AdminCommunityNote> items;
  final int page;
  final bool hasMore;
  final int total;
  final bool isLoadingMore;

  AdminCommunityNotesState copyWith({List<AdminCommunityNote>? items, int? page, bool? hasMore, bool? isLoadingMore}) {
    return AdminCommunityNotesState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Loads the first page for a given `status` filter on `build`, and appends
/// further pages via [loadMore] — same shape as `SearchResultsController`.
/// After an approve/reject mutation, the caller should
/// `ref.invalidateSelf()`/`ref.invalidate(...)` this provider rather than
/// try to merge the mutation response in place (see the repository's doc
/// comment on why).
class AdminCommunityNotesController extends FamilyAsyncNotifier<AdminCommunityNotesState, String> {
  @override
  Future<AdminCommunityNotesState> build(String status) async {
    final result = await ref.read(adminCommunityNotesRepositoryProvider).list(status: status, page: 1);
    return AdminCommunityNotesState(
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
    final result = await ref.read(adminCommunityNotesRepositoryProvider).list(status: arg, page: current.page + 1);
    state = AsyncData(
      AdminCommunityNotesState(
        items: [...current.items, ...result.items],
        page: result.currentPage,
        hasMore: result.hasMore,
        total: result.total,
      ),
    );
  }
}

final adminCommunityNotesProvider =
    AsyncNotifierProvider.family<AdminCommunityNotesController, AdminCommunityNotesState, String>(
      AdminCommunityNotesController.new,
    );

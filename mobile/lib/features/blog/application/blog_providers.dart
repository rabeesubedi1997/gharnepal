import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paginated_result.dart';
import '../../../core/network/providers.dart';
import '../data/blog_repository.dart';
import '../data/models/blog_post.dart';
import '../data/models/blog_post_summary.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(apiClient: ref.watch(apiClientProvider));
});

/// The current page of the manual Previous/Next pager, matching the
/// website's own paging UI (no infinite scroll on this list).
final blogPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final blogListProvider = FutureProvider.autoDispose<PaginatedResult<BlogPostSummary>>((ref) {
  final page = ref.watch(blogPageProvider);
  return ref.read(blogRepositoryProvider).list(page: page);
});

final blogPostProvider = FutureProvider.autoDispose.family<BlogPost, String>((ref, slug) {
  return ref.read(blogRepositoryProvider).detail(slug);
});

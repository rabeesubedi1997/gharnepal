import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_blog_repository.dart';
import '../data/models/admin_blog_post.dart';

final adminBlogRepositoryProvider = Provider<AdminBlogRepository>((ref) {
  return AdminBlogRepository(apiClient: ref.watch(apiClientProvider));
});

final adminBlogListProvider = FutureProvider.autoDispose<List<AdminBlogPost>>((ref) {
  return ref.watch(adminBlogRepositoryProvider).list();
});

final adminBlogPostProvider = FutureProvider.autoDispose.family<AdminBlogPost, int>((ref, id) {
  return ref.watch(adminBlogRepositoryProvider).detail(id);
});

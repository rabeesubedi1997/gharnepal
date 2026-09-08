import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_seo_repository.dart';
import '../data/models/seo_page_detail.dart';
import '../data/models/seo_page_summary.dart';

final adminSeoRepositoryProvider = Provider<AdminSeoRepository>((ref) {
  return AdminSeoRepository(apiClient: ref.watch(apiClientProvider));
});

/// `type` filter: null (all) | static | listing | neighborhood | agency | blog.
final adminSeoTypeFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final adminSeoQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final adminSeoPagesListProvider = FutureProvider.autoDispose<List<SeoPageSummary>>((ref) {
  final type = ref.watch(adminSeoTypeFilterProvider);
  final query = ref.watch(adminSeoQueryProvider);
  return ref.watch(adminSeoRepositoryProvider).pages(type: type, q: query.isEmpty ? null : query);
});

final adminSeoPageProvider = FutureProvider.autoDispose.family<SeoPageDetail, String>((ref, key) {
  return ref.watch(adminSeoRepositoryProvider).page(key);
});

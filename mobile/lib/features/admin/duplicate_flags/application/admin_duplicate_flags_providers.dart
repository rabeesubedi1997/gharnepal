import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_duplicate_flags_repository.dart';
import '../data/models/admin_duplicate_flag.dart';

final adminDuplicateFlagsRepositoryProvider = Provider<AdminDuplicateFlagsRepository>((ref) {
  return AdminDuplicateFlagsRepository(apiClient: ref.watch(apiClientProvider));
});

final adminDuplicateFlagsStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'unreviewed');
final adminDuplicateFlagsPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final adminDuplicateFlagsListProvider = FutureProvider.autoDispose<PaginatedResult<AdminDuplicateFlag>>((ref) {
  final status = ref.watch(adminDuplicateFlagsStatusFilterProvider);
  final page = ref.watch(adminDuplicateFlagsPageProvider);
  return ref.read(adminDuplicateFlagsRepositoryProvider).list(status: status, page: page);
});

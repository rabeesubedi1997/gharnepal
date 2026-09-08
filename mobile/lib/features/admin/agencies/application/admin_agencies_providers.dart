import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_agencies_repository.dart';
import '../data/models/admin_agency.dart';

final adminAgenciesRepositoryProvider = Provider<AdminAgenciesRepository>((ref) {
  return AdminAgenciesRepository(apiClient: ref.watch(apiClientProvider));
});

final adminAgenciesStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final adminAgenciesPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final adminAgenciesListProvider = FutureProvider.autoDispose<PaginatedResult<AdminAgency>>((ref) {
  final status = ref.watch(adminAgenciesStatusFilterProvider);
  final page = ref.watch(adminAgenciesPageProvider);
  return ref.read(adminAgenciesRepositoryProvider).list(status: status, page: page);
});

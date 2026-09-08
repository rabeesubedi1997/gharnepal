import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_reports_repository.dart';
import '../data/models/admin_listing_report.dart';

final adminReportsRepositoryProvider = Provider<AdminReportsRepository>((ref) {
  return AdminReportsRepository(apiClient: ref.watch(apiClientProvider));
});

final adminReportsStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'open');
final adminReportsPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final adminReportsListProvider = FutureProvider.autoDispose<PaginatedResult<AdminListingReport>>((ref) {
  final status = ref.watch(adminReportsStatusFilterProvider);
  final page = ref.watch(adminReportsPageProvider);
  return ref.read(adminReportsRepositoryProvider).list(status: status, page: page);
});

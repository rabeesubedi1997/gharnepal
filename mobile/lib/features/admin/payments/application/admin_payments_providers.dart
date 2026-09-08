import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_payments_repository.dart';
import '../data/models/admin_payment_transaction.dart';

final adminPaymentsRepositoryProvider = Provider<AdminPaymentsRepository>((ref) {
  return AdminPaymentsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Status filter: null | pending | completed | failed | refunded.
final adminPaymentsStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Manual Previous/Next pager, matching the paginated 25/page endpoint.
final adminPaymentsPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final adminPaymentsListProvider = FutureProvider.autoDispose<PaginatedResult<AdminPaymentTransaction>>((ref) {
  final status = ref.watch(adminPaymentsStatusFilterProvider);
  final page = ref.watch(adminPaymentsPageProvider);
  return ref.read(adminPaymentsRepositoryProvider).list(status: status, page: page);
});

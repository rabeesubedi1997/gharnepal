import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/featured_plan.dart';
import '../data/models/payment_transaction.dart';
import '../data/payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(apiClient: ref.watch(apiClientProvider));
});

final featuredPlansProvider = FutureProvider<List<FeaturedPlan>>((ref) {
  return ref.read(paymentsRepositoryProvider).plans();
});

/// Payment History — first page only (same simplification as other account
/// list screens in this app; a Nepal listing owner's transaction history is
/// realistically small).
final paymentHistoryProvider = FutureProvider.autoDispose<List<PaymentTransaction>>((ref) async {
  final result = await ref.read(paymentsRepositoryProvider).history();
  return result.items;
});

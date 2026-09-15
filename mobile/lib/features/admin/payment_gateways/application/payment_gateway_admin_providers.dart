import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/models/admin_payment_gateway.dart';
import '../data/models/gateway_catalog_entry.dart';
import '../data/payment_gateway_admin_repository.dart';

final paymentGatewayAdminRepositoryProvider = Provider<PaymentGatewayAdminRepository>((ref) {
  return PaymentGatewayAdminRepository(apiClient: ref.watch(apiClientProvider));
});

/// Static-ish — the supported provider list only changes with a deploy.
final gatewayCatalogProvider = FutureProvider<List<GatewayCatalogEntry>>((ref) {
  return ref.watch(paymentGatewayAdminRepositoryProvider).catalog();
});

final adminPaymentGatewaysProvider = FutureProvider.autoDispose<List<AdminPaymentGateway>>((ref) {
  return ref.watch(paymentGatewayAdminRepositoryProvider).list();
});

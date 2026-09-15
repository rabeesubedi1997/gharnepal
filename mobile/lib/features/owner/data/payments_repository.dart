import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/checkout_instruction.dart';
import 'models/featured_plan.dart';
import 'models/payment_gateway_option.dart';
import 'models/payment_transaction.dart';

class PurchaseResult {
  PurchaseResult({required this.transaction, required this.checkout});

  final PaymentTransaction transaction;
  final CheckoutInstruction checkout;
}

/// Talks to the admin-configurable featured-listing payment flow: whatever
/// gateways an admin has enabled (sandbox, manual, eSewa, Khalti, IME Pay,
/// PayPal — see `PaymentGatewayDriverRegistry` on the backend) show up here
/// exactly as `GET /payment-gateways` lists them, nothing hardcoded.
class PaymentsRepository {
  PaymentsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Public, no auth — the static boost_7/boost_15/boost_30 catalog.
  Future<List<FeaturedPlan>> plans() async {
    try {
      final response = await _dio.get('/featured-plans');
      return (response.data['data'] as List<dynamic>)
          .map((p) => FeaturedPlan.fromJson(p as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Public, no auth — every payment method an admin currently has enabled.
  Future<List<PaymentGatewayOption>> gateways() async {
    try {
      final response = await _dio.get('/payment-gateways');
      return (response.data['data'] as List<dynamic>)
          .map((g) => PaymentGatewayOption.fromJson(g as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Creates a `pending` `PaymentTransaction` for the chosen plan + gateway.
  /// Doesn't touch the listing's featured status yet — that happens either
  /// on [confirm] (sandbox only) or once the gateway's own callback (or an
  /// admin, for manual) settles it server-side.
  Future<PurchaseResult> purchase(int listingId, String planKey, int gatewayConfigId) async {
    try {
      final response = await _dio.post(
        '/listings/$listingId/feature',
        data: {'plan_key': planKey, 'gateway_config_id': gatewayConfigId},
      );
      return PurchaseResult(
        transaction: PaymentTransaction.fromJson(response.data['data'] as Map<String, dynamic>),
        checkout: CheckoutInstruction.fromJson(response.data['checkout'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Sandbox-only stand-in for a gateway webhook: the buyer simulates their
  /// own outcome. Single-use — the transaction must still be `pending`, so
  /// calling this twice on the same id fails with a 422 the second time.
  Future<PaymentTransaction> confirm(int transactionId, {required bool success}) async {
    try {
      final response = await _dio.post(
        '/account/payments/$transactionId/confirm',
        data: {'outcome': success ? 'success' : 'failure'},
      );
      return PaymentTransaction.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<PaginatedResult<PaymentTransaction>> history({int page = 1}) async {
    try {
      final response = await _dio.get('/account/payments', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, PaymentTransaction.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

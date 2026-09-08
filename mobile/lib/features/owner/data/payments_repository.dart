import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/featured_plan.dart';
import 'models/payment_transaction.dart';

/// Talks to the sandbox featured-listing payment flow:
/// `App\Domain\Payments\Services\SandboxPaymentGateway` — there is no real
/// gateway wired up yet, "confirm" just simulates a success/failure
/// callback the owner triggers themselves.
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

  /// Creates a `pending` `PaymentTransaction` for the chosen plan — doesn't
  /// touch the listing's featured status yet, that only happens on
  /// [confirm] with `outcome: 'success'`.
  Future<PaymentTransaction> purchase(int listingId, String planKey) async {
    try {
      final response = await _dio.post('/listings/$listingId/feature', data: {'plan_key': planKey});
      return PaymentTransaction.fromJson(response.data['data'] as Map<String, dynamic>);
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

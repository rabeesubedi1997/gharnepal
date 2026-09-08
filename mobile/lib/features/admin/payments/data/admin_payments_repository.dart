import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_payment_transaction.dart';

/// Talks to `/admin/payments` — the admin payments/refunds moderation
/// surface. Mirrors the website's admin Payments page.
class AdminPaymentsRepository {
  AdminPaymentsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// `status`: pending | completed | failed | refunded (optional filter).
  Future<PaginatedResult<AdminPaymentTransaction>> list({String? status, int page = 1}) async {
    try {
      final response = await _dio.get(
        '/admin/payments',
        queryParameters: {'status': ?status, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminPaymentTransaction.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Only legal from `status == 'completed'` — the backend returns a 422
  /// otherwise, which the caller should surface to the admin.
  Future<AdminPaymentTransaction> refund(int id) async {
    try {
      final response = await _dio.patch('/admin/payments/$id/refund');
      return AdminPaymentTransaction.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

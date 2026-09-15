import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_payment_gateway.dart';
import 'models/gateway_catalog_entry.dart';

/// Talks to `/admin/payment-gateways` — the admin CRUD for every merchant
/// account (eSewa, Khalti, IME Pay, PayPal, manual, sandbox). See
/// backend/app/Http/Controllers/Api/V1/Admin/PaymentGatewayConfigController.php.
class PaymentGatewayAdminRepository {
  PaymentGatewayAdminRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<GatewayCatalogEntry>> catalog() async {
    try {
      final response = await _dio.get('/admin/payment-gateways/catalog');
      return (response.data['data'] as List<dynamic>)
          .map((e) => GatewayCatalogEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<AdminPaymentGateway>> list() async {
    try {
      final response = await _dio.get('/admin/payment-gateways');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AdminPaymentGateway.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminPaymentGateway> create({
    required String provider,
    required String label,
    bool isSandbox = true,
    String? instructions,
    Map<String, String> credentials = const {},
  }) async {
    try {
      final response = await _dio.post(
        '/admin/payment-gateways',
        data: {
          'provider': provider,
          'label': label,
          'is_sandbox': isSandbox,
          'instructions': ?instructions,
          'credentials': credentials,
        },
      );
      return AdminPaymentGateway.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Every param optional — pass only what changed. `credentials` merges
  /// into what's already stored (a blank field keeps its current value),
  /// never replaces the whole set.
  Future<AdminPaymentGateway> update(
    int id, {
    String? label,
    bool? isEnabled,
    String? instructions,
    Map<String, String>? credentials,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/payment-gateways/$id',
        data: {
          'label': ?label,
          'is_enabled': ?isEnabled,
          'instructions': ?instructions,
          'credentials': ?credentials,
        },
      );
      return AdminPaymentGateway.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/payment-gateways/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

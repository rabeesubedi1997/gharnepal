import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/branding.dart';

/// Talks to `GET /branding` — public, no auth. Used wherever the app needs
/// to show the admin-configured site name/logo instead of a hardcoded one
/// (mirrors the website's own `useBranding`/`BrandingSync`).
class BrandingRepository {
  BrandingRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<Branding> get() async {
    try {
      final response = await _dio.get('/branding');
      return Branding.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

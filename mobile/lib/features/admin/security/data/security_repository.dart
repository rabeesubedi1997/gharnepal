import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_security.dart';

/// Talks to `/admin/security` and `/admin/mail-test`. See
/// backend/app/Http/Controllers/Api/V1/Admin/SecurityController.php and
/// MailTestController.php.
class SecurityRepository {
  SecurityRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<AdminSecurity> get() async {
    try {
      final response = await _dio.get('/admin/security');
      return AdminSecurity.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Every param optional — pass only what changed. A blank/omitted secret
  /// key keeps whatever is already configured (the backend never echoes it
  /// back, so there's nothing to prefill and re-send).
  Future<AdminSecurity> update({bool? recaptchaEnabled, String? recaptchaSiteKey, String? recaptchaSecretKey}) async {
    try {
      final response = await _dio.post(
        '/admin/security',
        data: {
          'recaptcha_enabled': ?recaptchaEnabled,
          'recaptcha_site_key': ?recaptchaSiteKey,
          'recaptcha_secret_key': ?recaptchaSecretKey,
        },
      );
      return AdminSecurity.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `to` blank/null sends to the logged-in admin's own email.
  Future<MailTestResult> sendTestEmail({String? to}) async {
    try {
      final response = await _dio.post('/admin/mail-test', data: {'to': ?to});
      return MailTestResult.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

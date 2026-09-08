import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_user.dart';

/// Talks to `/account/profile`, `/account/password`, `/account/phone/*`.
/// Mirrors frontend/src/lib/api/auth.ts's settings-related hooks.
class SettingsRepository {
  SettingsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Only `name` is editable here — there's no re-verification flow for
  /// email yet, and phone changes go through the OTP-backed endpoints below.
  Future<AuthUser> updateProfile(String name) async {
    try {
      final response = await _dio.put('/account/profile', data: {'name': name});
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.put(
        '/account/password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> requestPhoneOtp(String phone) async {
    try {
      await _dio.post('/account/phone/request-otp', data: {'phone': phone});
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// On success this is also how the user's canonical phone number actually
  /// gets set/overwritten server-side — there's no separate "update phone"
  /// endpoint, the OTP flow IS the phone-change flow.
  Future<void> verifyPhoneOtp({required String phone, required String code}) async {
    try {
      await _dio.post('/account/phone/verify-otp', data: {'phone': phone, 'code': code});
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

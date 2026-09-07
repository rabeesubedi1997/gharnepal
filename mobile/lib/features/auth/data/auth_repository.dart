import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import 'auth_user.dart';

/// Talks to the `/auth/*` and `/account/*` endpoints. Mirrors
/// frontend/src/lib/api/auth.ts, minus the CSRF-cookie dance (`ensureCsrfCookie`)
/// which only applies to the web SPA's stateful session auth — this client
/// authenticates with the bearer token Phase 0 added to the backend.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required this._tokenStorage})
    : _dio = apiClient.dio;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      return await _saveTokenAndReturnUser(response.data);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return await _saveTokenAndReturnUser(response.data);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Returns the current user, or `null` for a guest (401) — mirroring the
  /// web's `useCurrentUser`, which treats "not logged in" as a normal result
  /// rather than an error.
  Future<AuthUser?> me() async {
    try {
      final response = await _dio.get('/auth/me');
      return AuthUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) return null;
      throw apiExceptionFrom(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      // Revoking server-side is best-effort; the token is discarded locally
      // either way so the app treats the user as logged out.
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<AuthUser> _saveTokenAndReturnUser(dynamic body) async {
    final token = body['token'] as String;
    await _tokenStorage.saveToken(token);
    return AuthUser.fromJson(body['data'] as Map<String, dynamic>);
  }
}

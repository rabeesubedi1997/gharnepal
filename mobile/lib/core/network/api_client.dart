import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_events.dart';
import 'token_storage.dart';

/// The app's single Dio instance: attaches the bearer token to every
/// request, and turns a 401 into a broadcast event (see [AuthEvents]) so the
/// auth session can react without this file depending on Riverpod.
///
/// There is no CSRF-cookie dance here (`ensureCsrfCookie` on the web) — a
/// Bearer-token client is stateless, so none of that stateful-SPA machinery
/// applies. See backend/app/Http/Controllers/Api/V1/Auth/AuthController.php.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiPath,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            AuthEvents.notifyUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio dio;
  final TokenStorage _tokenStorage;
}

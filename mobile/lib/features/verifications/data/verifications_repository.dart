import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/user_verification.dart';

/// Talks to `/account/verifications` — user identity/credential KYC.
class VerificationsRepository {
  VerificationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<UserVerification>> list() async {
    try {
      final response = await _dio.get('/account/verifications');
      return (response.data['data'] as List<dynamic>)
          .map((v) => UserVerification.fromJson(v as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `type`: identity | agent_license | agency_document. `filePath` must be a
  /// jpg/jpeg/png/pdf under 10MB — the backend enforces the same limits.
  Future<UserVerification> submit({required String type, required String filePath}) async {
    try {
      final response = await _dio.post(
        '/account/verifications',
        data: FormData.fromMap({'type': type, 'document': await MultipartFile.fromFile(filePath)}),
      );
      return UserVerification.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

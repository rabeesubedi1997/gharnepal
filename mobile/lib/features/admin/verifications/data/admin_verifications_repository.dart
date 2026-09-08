import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_user_verification.dart';

/// Talks to `/admin/verifications/*` — the moderation side of user KYC
/// review (see backend/app/Http/Controllers/Api/V1/Admin/VerificationController.php).
class AdminVerificationsRepository {
  AdminVerificationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<AdminUserVerification>> list({String status = 'pending', int page = 1}) async {
    try {
      final response = await _dio.get(
        '/admin/verifications',
        queryParameters: {'status': status, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminUserVerification.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminUserVerification> approve(int id) async {
    try {
      final response = await _dio.patch('/admin/verifications/$id/approve');
      return AdminUserVerification.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminUserVerification> reject(int id, String reason) async {
    try {
      final response = await _dio.patch('/admin/verifications/$id/reject', data: {'reason': reason});
      return AdminUserVerification.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_duplicate_flag.dart';

/// Talks to `/admin/duplicate-flags/*`. There is no merge endpoint — only
/// confirm/dismiss.
class AdminDuplicateFlagsRepository {
  AdminDuplicateFlagsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<AdminDuplicateFlag>> list({String status = 'unreviewed', int page = 1}) async {
    try {
      final response = await _dio.get('/admin/duplicate-flags', queryParameters: {'status': status, 'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminDuplicateFlag.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminDuplicateFlag> confirm(int id) async {
    try {
      final response = await _dio.patch('/admin/duplicate-flags/$id/confirm');
      return AdminDuplicateFlag.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminDuplicateFlag> dismiss(int id) async {
    try {
      final response = await _dio.patch('/admin/duplicate-flags/$id/dismiss');
      return AdminDuplicateFlag.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/rating.dart';

/// Talks to `/admin/ratings/*`. Paginated 25/page.
class AdminRatingsRepository {
  AdminRatingsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// `status` (`visible`/`hidden`) is `sometimes` server-side — pass null
  /// (or omit) for "all".
  Future<PaginatedResult<Rating>> list({String? status, int page = 1}) async {
    try {
      final response = await _dio.get(
        '/admin/ratings',
        queryParameters: {'status': ?status, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, Rating.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Reloaded with relations — safe to merge the response in place (unlike
  /// the community-notes approve/reject endpoints).
  Future<Rating> hide(int id) async {
    try {
      final response = await _dio.patch('/admin/ratings/$id/hide');
      return Rating.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<Rating> unhide(int id) async {
    try {
      final response = await _dio.patch('/admin/ratings/$id/unhide');
      return Rating.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

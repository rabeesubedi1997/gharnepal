import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/blog_post.dart';
import 'models/blog_post_summary.dart';

/// Talks to `/blog` — public, no auth, fixed 9-per-page (not client
/// configurable).
class BlogRepository {
  BlogRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<BlogPostSummary>> list({int page = 1}) async {
    try {
      final response = await _dio.get('/blog', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, BlogPostSummary.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<BlogPost> detail(String slug) async {
    try {
      final response = await _dio.get('/blog/$slug');
      return BlogPost.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_blog_post.dart';

/// Talks to `/admin/blog` — the Blog CMS. There is no separate "publish"
/// endpoint; publishing IS create/update with `status: 'published'`. Slug
/// is auto-generated on create and immutable on update — never sent.
class AdminBlogRepository {
  AdminBlogRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Not paginated, ordered newest-first, includes drafts.
  Future<List<AdminBlogPost>> list() async {
    try {
      final response = await _dio.get('/admin/blog');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AdminBlogPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminBlogPost> detail(int id) async {
    try {
      final response = await _dio.get('/admin/blog/$id');
      return AdminBlogPost.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `published_at` is stamped server-side only the first time a post
  /// becomes `published` — later edits never bump it, even if `status:
  /// published` is resent.
  Future<AdminBlogPost> create({
    required String title,
    String? excerpt,
    required String body,
    required String status,
    String? coverImagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/blog',
        data: FormData.fromMap({
          'title': title,
          'excerpt': ?excerpt,
          'body': body,
          'status': status,
          if (coverImagePath != null) 'cover_image': await MultipartFile.fromFile(coverImagePath),
        }),
      );
      return AdminBlogPost.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// All fields optional (`sometimes` server-side) — the old cover image is
  /// auto-deleted if a new one is sent. Sent as multipart POST + `_method=PUT`.
  Future<AdminBlogPost> update(
    int id, {
    String? title,
    String? excerpt,
    String? body,
    String? status,
    String? coverImagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/blog/$id',
        data: FormData.fromMap({
          '_method': 'PUT',
          'title': ?title,
          'excerpt': ?excerpt,
          'body': ?body,
          'status': ?status,
          if (coverImagePath != null) 'cover_image': await MultipartFile.fromFile(coverImagePath),
        }),
      );
      return AdminBlogPost.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/blog/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

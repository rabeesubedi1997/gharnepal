import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_community_note.dart';

/// Talks to `/admin/community-notes/*`. Paginated 20/page.
class AdminCommunityNotesRepository {
  AdminCommunityNotesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// `status` is an unvalidated free string, default `pending` server-side.
  Future<PaginatedResult<AdminCommunityNote>> list({String status = 'pending', int page = 1}) async {
    try {
      final response = await _dio.get(
        '/admin/community-notes',
        queryParameters: {'status': status, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminCommunityNote.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Note: the response is NOT reloaded with `submitted_by`/`neighborhood`
  /// relations (only the list endpoint eager-loads those) — callers should
  /// refetch the list rather than merge this response into place.
  Future<AdminCommunityNote> approve(int id) async {
    try {
      final response = await _dio.patch('/admin/community-notes/$id/approve');
      return AdminCommunityNote.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Same relation caveat as [approve].
  Future<AdminCommunityNote> reject(int id, {required String reason}) async {
    try {
      final response = await _dio.patch('/admin/community-notes/$id/reject', data: {'reason': reason});
      return AdminCommunityNote.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_conversation.dart';
import 'models/admin_message.dart';

/// Talks to `/admin/conversations` — the "reply as support" moderation
/// surface. Any admin can post into any conversation via [sendMessage].
class AdminConversationsRepository {
  AdminConversationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// `status`: open | closed (optional). `q` matches buyer/owner name-or-email.
  Future<PaginatedResult<AdminConversation>> conversations({String? status, String? q, int page = 1}) async {
    try {
      final response = await _dio.get(
        '/admin/conversations',
        queryParameters: {'status': ?status, if (q != null && q.isNotEmpty) 'q': q, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminConversation.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminConversation> conversation(int id) async {
    try {
      final response = await _dio.get('/admin/conversations/$id');
      return AdminConversation.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminMessage> sendMessage(int conversationId, String body) async {
    try {
      final response = await _dio.post('/admin/conversations/$conversationId/messages', data: {'body': body});
      return AdminMessage.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

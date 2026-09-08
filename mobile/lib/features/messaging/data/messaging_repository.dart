import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/conversation.dart';
import 'models/message.dart';

/// Talks to `/conversations` and `/conversations/{id}/messages`. Mirrors
/// frontend/src/lib/api/messaging.ts.
class MessagingRepository {
  MessagingRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<Conversation>> conversations({int page = 1}) async {
    try {
      final response = await _dio.get('/conversations', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, Conversation.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Fetching a conversation also marks its messages as read server-side —
  /// there is no separate mark-read endpoint for messaging.
  Future<Conversation> conversation(int id) async {
    try {
      final response = await _dio.get('/conversations/$id');
      return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Starts (or reuses) a thread about a listing or a property request —
  /// exactly one of the two ids must be given. Idempotent per (listing,
  /// buyer) or (property request, responder) pair on the backend.
  Future<Conversation> start({int? listingId, int? propertyRequestId, required String message}) async {
    assert(
      (listingId == null) != (propertyRequestId == null),
      'Exactly one of listingId or propertyRequestId must be given.',
    );
    try {
      final response = await _dio.post(
        '/conversations',
        data: {
          'listing_id': ?listingId,
          'property_request_id': ?propertyRequestId,
          'message': message,
        },
      );
      return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<Message> sendMessage(int conversationId, String body) async {
    try {
      final response = await _dio.post('/conversations/$conversationId/messages', data: {'body': body});
      return Message.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

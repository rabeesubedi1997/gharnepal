import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/assistant_chat_response.dart';

/// Talks to the rule-based property-search assistant (see backend
/// AssistantService/PropertySearchParser — no paid AI API involved).
/// Mirrors frontend/src/lib/api/assistant.ts.
class AssistantRepository {
  AssistantRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<AssistantChatResponse> chat({
    required String message,
    int? conversationId,
    String? guestToken,
  }) async {
    try {
      final response = await _dio.post(
        '/assistant/chat',
        data: {
          'message': message,
          'conversation_id': ?conversationId,
          'guest_token': ?guestToken,
        },
      );
      return AssistantChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

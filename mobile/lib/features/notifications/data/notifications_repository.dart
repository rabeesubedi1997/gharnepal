import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/app_notification.dart';

class NotificationsResult {
  NotificationsResult({required this.items, required this.unreadCount});

  final List<AppNotification> items;
  final int unreadCount;
}

/// Talks to `/notifications`. Mirrors frontend/src/lib/api/notifications.ts.
class NotificationsRepository {
  NotificationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<NotificationsResult> list() async {
    try {
      final response = await _dio.get('/notifications');
      final body = response.data as Map<String, dynamic>;
      final meta = body['meta'] as Map<String, dynamic>? ?? const {};
      return NotificationsResult(
        items: (body['data'] as List<dynamic>)
            .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
            .toList(),
        unreadCount: meta['unread_count'] as int? ?? 0,
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

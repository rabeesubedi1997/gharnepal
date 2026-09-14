import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/platform_stats.dart';

/// Talks to `GET /platform-stats` — public, no auth.
class PlatformStatsRepository {
  PlatformStatsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PlatformStats> fetch() async {
    try {
      final response = await _dio.get('/platform-stats');
      return PlatformStats.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

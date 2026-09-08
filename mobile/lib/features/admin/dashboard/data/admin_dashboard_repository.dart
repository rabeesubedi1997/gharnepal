import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_dashboard_stats.dart';

/// Talks to `/admin/dashboard/*` — a single non-paginated stats snapshot.
class AdminDashboardRepository {
  AdminDashboardRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<AdminDashboardStats> stats() async {
    try {
      final response = await _dio.get('/admin/dashboard/stats');
      return AdminDashboardStats.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

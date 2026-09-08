import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_agency.dart';

/// Talks to `/admin/agencies/*`.
class AdminAgenciesRepository {
  AdminAgenciesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<AdminAgency>> list({String? status, int page = 1}) async {
    try {
      final response = await _dio.get(
        '/admin/agencies',
        queryParameters: {if (status != null && status.isNotEmpty) 'status': status, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminAgency.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminAgency> verify(int id) async {
    try {
      final response = await _dio.patch('/admin/agencies/$id/verify');
      return AdminAgency.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminAgency> suspend(int id) async {
    try {
      final response = await _dio.patch('/admin/agencies/$id/suspend');
      return AdminAgency.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

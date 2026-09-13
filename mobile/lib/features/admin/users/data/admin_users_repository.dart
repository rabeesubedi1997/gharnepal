import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_user.dart';

/// Talks to `/admin/users/*`.
class AdminUsersRepository {
  AdminUsersRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<AdminUser>> list({
    String? q,
    String? role,
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/users',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (role != null && role.isNotEmpty) 'role': role,
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
        },
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminUser.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Lets an admin onboard someone directly instead of everyone always
  /// having to self-register first. Requesting 'admin'/'super_admin' in
  /// [roles] is only honored server-side if the acting user is themselves
  /// a super admin — otherwise this throws a 422 via [ApiException].
  Future<AdminUser> create({
    required String name,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/users',
        data: {'name': name, 'email': email, 'password': password, 'roles': roles},
      );
      return AdminUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminUser> updateStatus(int id, String status) async {
    try {
      final response = await _dio.patch('/admin/users/$id/status', data: {'status': status});
      return AdminUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Full replace/sync of a user's roles — not a merge.
  Future<AdminUser> updateRoles(int id, List<String> roles) async {
    try {
      final response = await _dio.put('/admin/users/$id/roles', data: {'roles': roles});
      return AdminUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

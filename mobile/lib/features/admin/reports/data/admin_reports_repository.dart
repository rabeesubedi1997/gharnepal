import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import 'models/admin_listing_report.dart';

/// Talks to `/admin/reports/*`.
class AdminReportsRepository {
  AdminReportsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<AdminListingReport>> list({String status = 'open', int page = 1}) async {
    try {
      final response = await _dio.get('/admin/reports', queryParameters: {'status': status, 'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AdminListingReport.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `status` is required (`reviewed`|`dismissed`|`action_taken`);
  /// `resolutionNote` is optional, max 1000 chars.
  Future<AdminListingReport> resolve(int id, {required String status, String? resolutionNote}) async {
    try {
      final response = await _dio.patch(
        '/admin/reports/$id/resolve',
        data: {
          'status': status,
          if (resolutionNote != null && resolutionNote.isNotEmpty) 'resolution_note': resolutionNote,
        },
      );
      return AdminListingReport.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

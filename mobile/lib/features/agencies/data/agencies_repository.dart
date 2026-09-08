import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/agency_profile.dart';
import 'models/agency_summary.dart';

/// Talks to `/agencies` — public, no auth. No search/filter params exist
/// server-side; the directory is small enough to just fetch in full.
class AgenciesRepository {
  AgenciesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AgencySummary>> list() async {
    try {
      final response = await _dio.get('/agencies');
      return (response.data['data'] as List<dynamic>)
          .map((a) => AgencySummary.fromJson(a as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Bound by slug, not id. 404s for an unverified/inactive agency — its
  /// profile is unreachable, not merely hidden from the directory.
  Future<AgencyProfile> detail(String slug) async {
    try {
      final response = await _dio.get('/agencies/$slug');
      return AgencyProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

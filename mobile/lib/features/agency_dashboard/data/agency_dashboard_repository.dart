import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/agency_dashboard_listing.dart';
import 'models/agency_inquiry.dart';
import 'models/agency_overview.dart';
import 'models/agency_site_visit.dart';

/// Talks to `/agency/dashboard/*` — a self-service dashboard for the
/// current user's own agency (any member). See
/// backend/app/Http/Controllers/Api/V1/Agency/DashboardController.php.
/// A 404 (as opposed to 403) from any of these means "not a member of any
/// agency" — surfaced via `ApiException.statusCode`, exactly the check the
/// screen uses to render its empty state.
class AgencyDashboardRepository {
  AgencyDashboardRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<AgencyOverview> overview() async {
    try {
      final response = await _dio.get('/agency/dashboard/overview');
      return AgencyOverview.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<PaginatedResult<AgencyDashboardListing>> listings({
    String? category,
    String? search,
    String sort = 'newest',
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/agency/dashboard/listings',
        queryParameters: {'category': ?category, 'search': ?search, 'sort': sort, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, AgencyDashboardListing.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<AgencyInquiry>> inquiries() async {
    try {
      final response = await _dio.get('/agency/dashboard/inquiries');
      return (response.data['data'] as List<dynamic>)
          .map((i) => AgencyInquiry.fromJson(i as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<AgencySiteVisit>> siteVisits() async {
    try {
      final response = await _dio.get('/agency/dashboard/site-visits');
      return (response.data['data'] as List<dynamic>)
          .map((v) => AgencySiteVisit.fromJson(v as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

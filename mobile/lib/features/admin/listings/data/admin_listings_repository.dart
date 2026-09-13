import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated_result.dart';
import '../../../listings/data/models/listing_detail.dart';

/// Talks to `/admin/listings/*` — the moderation queue. Responses use the
/// same `PropertyListingDetailResource` as the public listing detail, so
/// this reuses [ListingDetail] rather than a parallel model; on this admin
/// route `amenities`/`trust`/`price_history`/`similar_listings` are
/// consistently empty, which [ListingDetail.fromJson] already defaults to.
class AdminListingsRepository {
  AdminListingsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Oldest-first FIFO for the 'pending_review' queue; newest-first for
  /// every other status (including 'all', meaning no status filter at all —
  /// the general "browse everything" view, not just the moderation queue).
  Future<PaginatedResult<ListingDetail>> list({
    String status = 'pending_review',
    bool featured = false,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/listings',
        queryParameters: {'status': status, if (featured) 'featured': true, 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, ListingDetail.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Only legal from `pending_review` — 422 on `status` otherwise.
  Future<ListingDetail> approve(int id) async {
    try {
      final response = await _dio.patch('/admin/listings/$id/approve');
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `reason` is required, max 500 chars.
  Future<ListingDetail> reject(int id, String reason) async {
    try {
      final response = await _dio.patch('/admin/listings/$id/reject', data: {'reason': reason});
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

/// 'all' (no filter) plus the full `PropertyListing.status` enum, for the
/// status filter dropdown.
const kAdminListingStatuses = [
  'all',
  'draft',
  'pending_review',
  'published',
  'paused',
  'rented',
  'sold',
  'rejected',
  'expired',
];

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/amenity.dart';
import 'models/listing_detail.dart';
import 'models/listing_summary.dart';
import 'models/rating.dart';
import 'models/search_filters.dart';

/// Talks to the public `/listings` endpoints. Mirrors
/// frontend/src/lib/api/listings.ts — search/detail/amenities need no auth;
/// ratings and reports mirror frontend/src/lib/api/{ratings,reports}.ts and
/// need a session for the mutating calls only (see
/// backend/app/Http/Controllers/Api/V1/{RatingController,ListingReportController}.php).
class ListingsRepository {
  ListingsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<ListingSummary>> search(SearchFilters filters, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/listings',
        queryParameters: {...filters.toQueryParams(), 'page': page},
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, ListingSummary.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<ListingDetail> detail(String slug) async {
    try {
      final response = await _dio.get('/listings/$slug');
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// The fixed, seeded catalog of selectable amenities — used by the
  /// Post-Property Wizard's Pricing step and Edit Listing.
  Future<List<Amenity>> amenities() async {
    try {
      final response = await _dio.get('/amenities');
      return (response.data['data'] as List<dynamic>)
          .map((a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// All visible ratings for a listing — public, no auth required. The
  /// endpoint paginates 10-per-page server-side (`RatingController::index`);
  /// this walks every page and flattens them, since a review list this
  /// small is simpler to render as one plain `Column` than to paginate.
  Future<List<ListingRating>> ratings(int listingId) async {
    try {
      final all = <ListingRating>[];
      var page = 1;
      while (true) {
        final response = await _dio.get('/listings/$listingId/ratings', queryParameters: {'page': page});
        final result = PaginatedResult.fromJson(response.data as Map<String, dynamic>, ListingRating.fromJson);
        all.addAll(result.items);
        if (!result.hasMore) break;
        page = result.currentPage + 1;
      }
      return all;
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Submits or edits the current user's own rating — `updateOrCreate`
  /// server-side, so calling this again just edits the existing rating
  /// rather than creating a second one.
  Future<void> rateListing(int listingId, {required int score, String? comment}) async {
    try {
      await _dio.post('/listings/$listingId/ratings', data: {'score': score, 'comment': ?comment});
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Deletes the current user's own rating on this listing (no-op server
  /// side if they never rated it).
  Future<void> deleteRating(int listingId) async {
    try {
      await _dio.delete('/listings/$listingId/ratings');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Flags a listing for moderator review. `reason` must be one of
  /// fraud/duplicate/sold_already/misleading/inappropriate/other (see
  /// `ListingReportController::store`'s validation).
  Future<void> reportListing(int listingId, {required String reason, String? details}) async {
    try {
      await _dio.post('/listings/$listingId/reports', data: {'reason': reason, 'details': ?details});
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/amenity.dart';
import 'models/listing_detail.dart';
import 'models/listing_summary.dart';
import 'models/search_filters.dart';

/// Talks to the public `/listings` endpoints. Mirrors
/// frontend/src/lib/api/listings.ts — no auth required for either call.
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
}

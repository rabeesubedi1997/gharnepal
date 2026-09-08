import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../listings/data/models/listing_summary.dart';

/// Talks to `/account/favorites`. Mirrors frontend/src/lib/api/favorites.ts.
/// The list endpoint returns the same full `ListingSummary` shape as
/// GET /listings — just filtered to what the user favorited.
class FavoritesRepository {
  FavoritesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<ListingSummary>> list({int page = 1}) async {
    try {
      final response = await _dio.get('/account/favorites', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, ListingSummary.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> add(int listingId) async {
    try {
      await _dio.post('/account/favorites', data: {'listing_id': listingId});
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> remove(int listingId) async {
    try {
      await _dio.delete('/account/favorites/$listingId');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

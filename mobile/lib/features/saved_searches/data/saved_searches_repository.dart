import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../listings/data/models/search_filters.dart';
import 'models/saved_search.dart';

/// Talks to `/account/saved-searches`. Mirrors frontend/src/lib/api/savedSearches.ts.
class SavedSearchesRepository {
  SavedSearchesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<SavedSearch>> list() async {
    try {
      final response = await _dio.get('/account/saved-searches');
      return (response.data['data'] as List<dynamic>)
          .map((s) => SavedSearch.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<SavedSearch> create({
    required String name,
    required SearchFilters filters,
    String alertFrequency = 'instant',
  }) async {
    try {
      final response = await _dio.post(
        '/account/saved-searches',
        data: {'name': name, 'filters': filters.toQueryParams(), 'alert_frequency': alertFrequency},
      );
      return SavedSearch.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Only `name`/`alert_frequency` can be changed — `filters` is fixed at
  /// creation on the backend.
  Future<SavedSearch> update(int id, {String? name, String? alertFrequency}) async {
    try {
      final response = await _dio.put(
        '/account/saved-searches/$id',
        data: {'name': ?name, 'alert_frequency': ?alertFrequency},
      );
      return SavedSearch.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/account/saved-searches/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

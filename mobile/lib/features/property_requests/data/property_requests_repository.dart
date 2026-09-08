import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/property_request.dart';

/// Talks to `/property-requests` (public board) and `/account/property-requests`
/// (mine). Mirrors frontend/src/lib/api/propertyRequests.ts.
class PropertyRequestsRepository {
  PropertyRequestsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<PropertyRequest>> board({
    String? purpose,
    String? propertyType,
    int? municipalityId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/property-requests',
        queryParameters: {
          'purpose': ?purpose,
          'property_type': ?propertyType,
          'municipality_id': ?municipalityId,
          'page': page,
        },
      );
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, PropertyRequest.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<PaginatedResult<PropertyRequest>> mine({int page = 1}) async {
    try {
      final response = await _dio.get('/account/property-requests', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, PropertyRequest.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<PropertyRequest> create({
    required String purpose,
    String? propertyType,
    int? budgetMin,
    int? budgetMax,
    int? bedroomsMin,
    int? municipalityId,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/property-requests',
        data: {
          'purpose': purpose,
          'property_type': ?propertyType,
          'budget_min': ?budgetMin,
          'budget_max': ?budgetMax,
          'bedrooms_min': ?bedroomsMin,
          'municipality_id': ?municipalityId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return PropertyRequest.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> close(int id) async {
    try {
      await _dio.patch('/property-requests/$id/close');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

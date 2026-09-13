import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_amenity.dart';

/// Talks to `/admin/amenities` — plain JSON CRUD, no file upload (unlike
/// Banners/Advertisements). See backend/app/Http/Controllers/Api/V1/Admin/
/// AmenityController.php.
class AdminAmenitiesRepository {
  AdminAmenitiesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AdminAmenity>> list() async {
    try {
      final response = await _dio.get('/admin/amenities');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AdminAmenity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminAmenity> create({
    required String key,
    required String name,
    String? nameNe,
    String? category,
    String? icon,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/amenities',
        data: {
          'key': key,
          'name': name,
          'name_ne': ?nameNe,
          'category': ?category,
          'icon': ?icon,
        },
      );
      return AdminAmenity.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminAmenity> update(
    int id, {
    String? key,
    String? name,
    String? nameNe,
    String? category,
    String? icon,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/amenities/$id',
        data: {
          'key': ?key,
          'name': ?name,
          'name_ne': ?nameNe,
          'category': ?category,
          'icon': ?icon,
        },
      );
      return AdminAmenity.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/amenities/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

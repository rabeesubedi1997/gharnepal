import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/district.dart';
import 'models/municipality.dart';
import 'models/neighborhood.dart';
import 'models/province.dart';
import 'models/ward.dart';

/// Talks to the public `/locations/*` read endpoints (non-paginated,
/// `{"data": [...]}`, shared with owners/consumers) and the admin-only
/// `/admin/locations/*` write endpoints. See
/// backend/app/Http/Controllers/Api/V1/{LocationController,Admin/LocationController}.php.
class AdminLocationsRepository {
  AdminLocationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  // ---- Reads (public, unfiltered lists except where noted) ----

  Future<List<Province>> provinces() async {
    try {
      final response = await _dio.get('/locations/provinces');
      return _dataList(response, Province.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<District>> districts({int? provinceId}) async {
    try {
      final response = await _dio.get(
        '/locations/districts',
        queryParameters: {'province_id': ?provinceId},
      );
      return _dataList(response, District.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Unlike the other levels, an unfiltered call here returns ALL
  /// municipalities rather than an empty list.
  Future<List<Municipality>> municipalities({int? districtId}) async {
    try {
      final response = await _dio.get(
        '/locations/municipalities',
        queryParameters: {'district_id': ?districtId},
      );
      return _dataList(response, Municipality.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<Ward>> wards({int? municipalityId}) async {
    try {
      final response = await _dio.get(
        '/locations/wards',
        queryParameters: {'municipality_id': ?municipalityId},
      );
      return _dataList(response, Ward.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<Neighborhood>> neighborhoods({int? wardId}) async {
    try {
      final response = await _dio.get(
        '/locations/neighborhoods',
        queryParameters: {'ward_id': ?wardId},
      );
      return _dataList(response, Neighborhood.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  // ---- Province CRUD ----

  Future<Province> createProvince({required String name, String? nameNe, required String code}) async {
    try {
      final response = await _dio.post(
        '/admin/locations/provinces',
        data: {'name': name, 'name_ne': ?nameNe, 'code': code},
      );
      return Province.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<Province> updateProvince(int id, {String? name, String? nameNe, String? code}) async {
    try {
      final response = await _dio.put(
        '/admin/locations/provinces/$id',
        data: {'name': ?name, 'name_ne': ?nameNe, 'code': ?code},
      );
      return Province.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteProvince(int id) async {
    try {
      await _dio.delete('/admin/locations/provinces/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  // ---- District CRUD ----

  Future<District> createDistrict({
    required int provinceId,
    required String name,
    String? nameNe,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/locations/districts',
        data: {'province_id': provinceId, 'name': name, 'name_ne': ?nameNe, 'code': code},
      );
      return District.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<District> updateDistrict(
    int id, {
    int? provinceId,
    String? name,
    String? nameNe,
    String? code,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/locations/districts/$id',
        data: {'province_id': ?provinceId, 'name': ?name, 'name_ne': ?nameNe, 'code': ?code},
      );
      return District.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteDistrict(int id) async {
    try {
      await _dio.delete('/admin/locations/districts/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  // ---- Municipality CRUD (multipart — supports an image) ----

  /// Creating one auto-provisions `wardCount` Ward rows 1..N server-side.
  Future<Municipality> createMunicipality({
    required int districtId,
    required String name,
    String? nameNe,
    required String type,
    required String code,
    required int wardCount,
    String? imagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/locations/municipalities',
        data: FormData.fromMap({
          'district_id': districtId,
          'name': name,
          if (nameNe != null && nameNe.isNotEmpty) 'name_ne': nameNe,
          'type': type,
          'code': code,
          'ward_count': wardCount,
          if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
        }),
      );
      return Municipality.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `ward_count` is not updatable here — omitted entirely. Sent as a
  /// multipart POST with a `_method=PUT` field since Laravel can't parse
  /// multipart bodies on a true PUT verb.
  Future<Municipality> updateMunicipality(
    int id, {
    int? districtId,
    String? name,
    String? nameNe,
    String? type,
    String? code,
    String? imagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/locations/municipalities/$id',
        data: FormData.fromMap({
          '_method': 'PUT',
          'district_id': ?districtId,
          'name': ?name,
          'name_ne': ?nameNe,
          'type': ?type,
          'code': ?code,
          if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
        }),
      );
      return Municipality.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteMunicipality(int id) async {
    try {
      await _dio.delete('/admin/locations/municipalities/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  // ---- Ward: create + delete only, no update endpoint ----

  Future<Ward> createWard({required int municipalityId, required int wardNumber, String? name}) async {
    try {
      final response = await _dio.post(
        '/admin/locations/wards',
        data: {'municipality_id': municipalityId, 'ward_number': wardNumber, 'name': ?name},
      );
      return Ward.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteWard(int id) async {
    try {
      await _dio.delete('/admin/locations/wards/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  // ---- Neighborhood CRUD ----

  /// Server forces `is_curated = true` on create — not client-settable here.
  Future<Neighborhood> createNeighborhood({
    required int wardId,
    required String name,
    String? nameNe,
    double? centroidLat,
    double? centroidLng,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/locations/neighborhoods',
        data: {
          'ward_id': wardId,
          'name': name,
          'name_ne': ?nameNe,
          'centroid_lat': ?centroidLat,
          'centroid_lng': ?centroidLng,
        },
      );
      return Neighborhood.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<Neighborhood> updateNeighborhood(
    int id, {
    String? name,
    String? nameNe,
    double? centroidLat,
    double? centroidLng,
    bool? isCurated,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/locations/neighborhoods/$id',
        data: {
          'name': ?name,
          'name_ne': ?nameNe,
          'centroid_lat': ?centroidLat,
          'centroid_lng': ?centroidLng,
          'is_curated': ?isCurated,
        },
      );
      return Neighborhood.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteNeighborhood(int id) async {
    try {
      await _dio.delete('/admin/locations/neighborhoods/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  List<T> _dataList<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    return (response.data['data'] as List<dynamic>)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

/// A location delete can fail with an uncaught DB FK violation (HTTP 500,
/// not a clean Laravel JSON error) when any property `Address` still
/// references it anywhere in its subtree. Show a generic message instead of
/// the raw fallback text in that case.
String friendlyDeleteErrorMessage(Object error) {
  if (error is ApiException && error.statusCode == 500) {
    return 'Could not delete — it may still be in use.';
  }
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}

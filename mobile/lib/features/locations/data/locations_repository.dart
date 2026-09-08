import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'district.dart';
import 'municipality.dart';
import 'neighborhood.dart';
import 'province.dart';
import 'ward.dart';

class LocationsRepository {
  LocationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Returns every municipality (not paginated — see `LocationController::municipalities`),
  /// used for the Home screen's "browse by city" grid.
  Future<List<Municipality>> municipalities({int? districtId}) async {
    try {
      final response = await _dio.get(
        '/locations/municipalities',
        queryParameters: {'district_id': ?districtId},
      );
      return (response.data['data'] as List<dynamic>)
          .map((m) => Municipality.fromJson(m as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// All 7 provinces — used as the top of the address cascade in the
  /// Post-Property Wizard's Location step.
  Future<List<Province>> provinces() async {
    try {
      final response = await _dio.get('/locations/provinces');
      return (response.data['data'] as List<dynamic>)
          .map((p) => Province.fromJson(p as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<District>> districts({required int provinceId}) async {
    try {
      final response = await _dio.get(
        '/locations/districts',
        queryParameters: {'province_id': provinceId},
      );
      return (response.data['data'] as List<dynamic>)
          .map((d) => District.fromJson(d as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<Ward>> wards({required int municipalityId}) async {
    try {
      final response = await _dio.get(
        '/locations/wards',
        queryParameters: {'municipality_id': municipalityId},
      );
      return (response.data['data'] as List<dynamic>)
          .map((w) => Ward.fromJson(w as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<Neighborhood>> neighborhoods({required int wardId}) async {
    try {
      final response = await _dio.get(
        '/locations/neighborhoods',
        queryParameters: {'ward_id': wardId},
      );
      return (response.data['data'] as List<dynamic>)
          .map((n) => Neighborhood.fromJson(n as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

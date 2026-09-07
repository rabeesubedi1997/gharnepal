import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'municipality.dart';

class LocationsRepository {
  LocationsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Returns every municipality (not paginated — see `LocationController::municipalities`),
  /// used for the Home screen's "browse by city" grid.
  Future<List<Municipality>> municipalities() async {
    try {
      final response = await _dio.get('/locations/municipalities');
      return (response.data['data'] as List<dynamic>)
          .map((m) => Municipality.fromJson(m as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

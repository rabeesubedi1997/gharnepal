import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'banner.dart';

class MarketingRepository {
  MarketingRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AppBanner>> banners() async {
    try {
      final response = await _dio.get('/banners');
      return (response.data['data'] as List<dynamic>)
          .map((b) => AppBanner.fromJson(b as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

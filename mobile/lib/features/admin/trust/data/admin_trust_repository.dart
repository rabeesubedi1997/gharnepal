import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../listings/data/models/trust_score.dart';
import 'models/trust_score_factor.dart';

/// Talks to `/admin/trust-score-factors` (global factor tuning) and
/// `/admin/listings/{id}/trust-override` (per-listing manual override) — see
/// backend/app/Http/Controllers/Api/V1/Admin/TrustScoreController.php.
class AdminTrustRepository {
  AdminTrustRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<TrustScoreFactor>> factors() async {
    try {
      final response = await _dio.get('/admin/trust-score-factors');
      return (response.data['data'] as List<dynamic>)
          .map((f) => TrustScoreFactor.fromJson(f as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `isActive`/`maxPoints` are independent — pass only what changed.
  Future<TrustScoreFactor> updateFactor(int id, {bool? isActive, int? maxPoints}) async {
    try {
      final response = await _dio.put(
        '/admin/trust-score-factors/$id',
        data: {'is_active': ?isActive, 'max_points': ?maxPoints},
      );
      return TrustScoreFactor.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<TrustScore> setOverride(int listingId, {required int overrideScore, required String note}) async {
    try {
      final response = await _dio.post(
        '/admin/listings/$listingId/trust-override',
        data: {'override_score': overrideScore, 'note': note},
      );
      return TrustScore.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<TrustScore> clearOverride(int listingId) async {
    try {
      final response = await _dio.delete('/admin/listings/$listingId/trust-override');
      return TrustScore.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

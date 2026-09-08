import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../neighborhoods/data/models/neighborhood_poi.dart';
import '../../../neighborhoods/data/models/neighborhood_profile.dart';
import '../../../neighborhoods/data/models/neighborhood_score.dart';

/// Talks to `/admin/neighborhoods/*` and `/admin/neighborhood-pois/*` — the
/// admin-only write side of neighborhood scoring/POIs. Reads (the picker
/// list + profile detail) reuse the existing public
/// `NeighborhoodsRepository`/`neighborhoodsProviders` directly since
/// `GET /neighborhoods` and `GET /neighborhoods/{id}` are the same endpoints
/// an admin and a regular visitor both call.
class AdminNeighborhoodScoresRepository {
  AdminNeighborhoodScoresRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// Full replace, not a patch — the caller must submit all 11
  /// `kNeighborhoodScoreFactors` keys every time (any key omitted here gets
  /// deleted server-side). `overall_score` is computed server-side and is
  /// never part of the request.
  Future<NeighborhoodProfile> saveScore(int neighborhoodId, List<NeighborhoodScoreFactor> factors) async {
    try {
      final response = await _dio.post(
        '/admin/neighborhoods/$neighborhoodId/score',
        data: {
          'factors': [
            for (final factor in factors) {'key': factor.key, 'score': factor.score, 'notes': factor.notes},
          ],
        },
      );
      return NeighborhoodProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<NeighborhoodPoi> createPoi(
    int neighborhoodId, {
    required String poiType,
    required String name,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/neighborhoods/$neighborhoodId/pois',
        data: {'poi_type': poiType, 'name': name, 'lat': lat, 'lng': lng},
      );
      return NeighborhoodPoi.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Note: the route is NOT nested under a neighborhood — just the bare POI
  /// id. There is no update endpoint; fixing a POI is delete + recreate.
  Future<void> deletePoi(int poiId) async {
    try {
      await _dio.delete('/admin/neighborhood-pois/$poiId');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

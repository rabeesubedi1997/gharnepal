import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/match_preference.dart';
import 'models/match_result.dart';

/// Talks to `/account/match-preferences` and `/account/match-results`.
class MatchingRepository {
  MatchingRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<MatchPreference> getPreferences() async {
    try {
      final response = await _dio.get('/account/match-preferences');
      return MatchPreference.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Upsert (single row per user). The backend recomputes match results
  /// synchronously before responding, so results are already fresh —
  /// [MatchingRepository.getResults] just needs a re-fetch, not a refresh.
  ///
  /// The three boolean fields are sent as real JSON booleans deliberately —
  /// the backend has a documented quirk where an empty-string `false` from a
  /// web form gets coerced to `null` by global middleware, so it re-reads
  /// booleans via `$request->boolean()`; a genuine JSON `false` (what Dio
  /// sends here) is unaffected by that and comes through correctly either way.
  Future<MatchPreference> savePreferences({
    String? purpose,
    String? propertyType,
    double? budgetMin,
    double? budgetMax,
    int? minBedrooms,
    int? preferredMunicipalityId,
    double? workLat,
    double? workLng,
    String? workLocationLabel,
    int? commuteLimitMinutes,
    int? familySize,
    bool? requiresSchoolNearby,
    bool? requiresParking,
    bool? investmentPurpose,
    List<String> lifestyleTags = const [],
  }) async {
    try {
      final response = await _dio.put(
        '/account/match-preferences',
        data: {
          'purpose': ?purpose,
          'property_type': ?propertyType,
          'budget_min': ?budgetMin,
          'budget_max': ?budgetMax,
          'min_bedrooms': ?minBedrooms,
          'preferred_municipality_id': ?preferredMunicipalityId,
          'work_lat': ?workLat,
          'work_lng': ?workLng,
          'work_location_label': ?workLocationLabel,
          'commute_limit_minutes': ?commuteLimitMinutes,
          'family_size': ?familySize,
          'requires_school_nearby': ?requiresSchoolNearby,
          'requires_parking': ?requiresParking,
          'investment_purpose': ?investmentPurpose,
          if (lifestyleTags.isNotEmpty) 'lifestyle_tags': lifestyleTags,
        },
      );
      return MatchPreference.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<MatchResult>> getResults() async {
    try {
      final response = await _dio.get('/account/match-results');
      return (response.data['data'] as List<dynamic>)
          .map((r) => MatchResult.fromJson(r as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// 422s (surfaced as an [ApiValidationException]) if the user has no saved
  /// preferences yet.
  Future<List<MatchResult>> refreshResults() async {
    try {
      final response = await _dio.post('/account/match-results/refresh');
      return (response.data['data'] as List<dynamic>)
          .map((r) => MatchResult.fromJson(r as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

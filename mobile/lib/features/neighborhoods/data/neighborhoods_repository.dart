import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/community_note.dart';
import 'models/neighborhood_profile.dart';
import 'models/neighborhood_summary.dart';

/// Talks to `/neighborhoods` — public directory + profile, mirroring
/// frontend/src/lib/api/neighborhoods.ts. Note: distinct from
/// `/locations/neighborhoods` (a lighter geo-lookup used by address pickers).
class NeighborhoodsRepository {
  NeighborhoodsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// No filters, no pagination — the backend returns every neighborhood and
  /// the directory page filters client-side.
  Future<List<NeighborhoodSummary>> list() async {
    try {
      final response = await _dio.get('/neighborhoods');
      return (response.data['data'] as List<dynamic>)
          .map((n) => NeighborhoodSummary.fromJson(n as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<NeighborhoodProfile> detail(int id) async {
    try {
      final response = await _dio.get('/neighborhoods/$id');
      return NeighborhoodProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Requires the user to be logged in AND phone-verified — the backend
  /// rejects with a validation error on the `phone` key otherwise. Always
  /// starts as `status: 'pending'`, never appears publicly until approved.
  Future<CommunityNote> submitCommunityNote(int neighborhoodId, {required String category, required String body}) async {
    try {
      final response = await _dio.post(
        '/neighborhoods/$neighborhoodId/community-notes',
        data: {'category': category, 'body': body},
      );
      return CommunityNote.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

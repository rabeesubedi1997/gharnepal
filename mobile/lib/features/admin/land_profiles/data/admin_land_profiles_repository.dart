import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../listings/data/models/land_profile.dart';

/// Reads `/properties/{propertyId}/land-profile` (the same auth:sanctum
/// route owners use — not admin-prefixed, but an admin may view any
/// property's profile through it) and writes the one admin-only action,
/// `/admin/properties/{propertyId}/land-profile/verify`.
class AdminLandProfilesRepository {
  AdminLandProfilesRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<LandProfile> get(int propertyId) async {
    try {
      final response = await _dio.get('/properties/$propertyId/land-profile');
      return LandProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `status`: unverified | partial | verified — the only admin-settable
  /// field on this resource (no separate rejection-reason field here).
  Future<LandProfile> verify(int propertyId, String status) async {
    try {
      final response = await _dio.patch(
        '/admin/properties/$propertyId/land-profile/verify',
        data: {'document_verification_status': status},
      );
      return LandProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

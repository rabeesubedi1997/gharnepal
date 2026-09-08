import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import 'models/viewing_request.dart';

/// Talks to `/viewing-requests`. Mirrors frontend/src/lib/api/viewingRequests.ts.
class ViewingRequestsRepository {
  ViewingRequestsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// `as`: 'requester' (my requests, default) or 'host' (requests for my
  /// listings) — both tabs on the Viewing Requests screen.
  Future<PaginatedResult<ViewingRequest>> list({String as = 'requester', int page = 1}) async {
    try {
      final response = await _dio.get('/viewing-requests', queryParameters: {'as': as, 'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, ViewingRequest.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<ViewingRequest> request({
    required int listingId,
    required DateTime proposedDatetime,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/viewing-requests',
        data: {
          'listing_id': listingId,
          'proposed_datetime': proposedDatetime.toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return ViewingRequest.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// action: confirm (host only) | reschedule (either) | cancel (either) |
  /// complete (host only). `datetime` required only for reschedule.
  Future<ViewingRequest> transition(int id, {required String action, DateTime? datetime}) async {
    try {
      final response = await _dio.patch(
        '/viewing-requests/$id/transition',
        data: {'action': action, if (datetime != null) 'datetime': datetime.toIso8601String()},
      );
      return ViewingRequest.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Requester-only. Resubmitting overwrites the previous verification.
  Future<ViewingRequest> submitVisitVerification(
    int id, {
    required bool visited,
    bool? matchedListing,
    bool? priceAccurate,
    bool? hostAttended,
    bool? documentsShown,
    String? overallComment,
  }) async {
    try {
      final response = await _dio.post(
        '/viewing-requests/$id/visit-verification',
        data: {
          'visited': visited,
          'matched_listing': ?matchedListing,
          'price_accurate': ?priceAccurate,
          'host_attended': ?hostAttended,
          'documents_shown': ?documentsShown,
          if (overallComment != null && overallComment.isNotEmpty) 'overall_comment': overallComment,
        },
      );
      return ViewingRequest.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

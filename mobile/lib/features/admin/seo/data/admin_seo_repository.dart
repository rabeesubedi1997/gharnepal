import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/seo_competitor_scan.dart';
import 'models/seo_page_detail.dart';
import 'models/seo_page_summary.dart';

/// Talks to `/admin/seo/*`. Every real page on the site has a synthetic
/// `page_key` (some containing a literal colon, e.g. `listing:some-slug`) —
/// every path that embeds one URL-encodes it first.
class AdminSeoRepository {
  AdminSeoRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  /// `type`: static | listing | neighborhood | agency | blog (optional).
  /// `q`: substring match on label/page_key (optional). Not paginated.
  Future<List<SeoPageSummary>> pages({String? type, String? q}) async {
    try {
      final response = await _dio.get(
        '/admin/seo/pages',
        queryParameters: {'type': ?type, if (q != null && q.isNotEmpty) 'q': q},
      );
      return (response.data['data'] as List<dynamic>)
          .map((e) => SeoPageSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<SeoPageDetail> page(String key) async {
    try {
      final response = await _dio.get('/admin/seo/pages/${Uri.encodeComponent(key)}');
      return SeoPageDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// JSON body (not multipart — `og_image_url` is a pasted URL string, not
  /// a file). Response omits `scans` — see [SeoPageEffectiveAndOverride].
  Future<SeoPageEffectiveAndOverride> updatePage(
    String key, {
    String? metaTitle,
    String? metaDescription,
    String? metaKeywords,
    String? ogImageUrl,
    String? canonicalPath,
    bool? robotsIndex,
    bool? robotsFollow,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/seo/pages/${Uri.encodeComponent(key)}',
        data: {
          'meta_title': ?metaTitle,
          'meta_description': ?metaDescription,
          'meta_keywords': ?metaKeywords,
          'og_image_url': ?ogImageUrl,
          'canonical_path': ?canonicalPath,
          'robots_index': ?robotsIndex,
          'robots_follow': ?robotsFollow,
          'status': status,
        },
      );
      return SeoPageEffectiveAndOverride.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Deletes the override row, resetting the page to its auto-generated
  /// default.
  Future<void> resetPage(String key) async {
    try {
      await _dio.delete('/admin/seo/pages/${Uri.encodeComponent(key)}');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// May 422 if the scrape fails — callers should surface `message` rather
  /// than treat it as a crash.
  Future<SeoCompetitorScan> scan(String key, String url) async {
    try {
      final response = await _dio.post('/admin/seo/pages/${Uri.encodeComponent(key)}/scan', data: {'url': url});
      return SeoCompetitorScan.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteScan(int scanId) async {
    try {
      await _dio.delete('/admin/seo/scans/$scanId');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

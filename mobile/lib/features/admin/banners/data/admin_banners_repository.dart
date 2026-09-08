import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_banner.dart';

/// Talks to `/admin/banners` — the homepage hero-slider CMS. Not paginated
/// (a flat list ordered by `sort_order`); there is no bulk-reorder endpoint,
/// so "move up/down" means two separate [update] calls swapping two rows'
/// `sort_order` values.
class AdminBannersRepository {
  AdminBannersRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AdminBanner>> list() async {
    try {
      final response = await _dio.get('/admin/banners');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AdminBanner.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminBanner> create({
    String? title,
    String? subtitle,
    String? linkUrl,
    String? ctaLabel,
    int? sortOrder,
    bool? isActive,
    required String imagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/banners',
        data: FormData.fromMap({
          'title': ?title,
          'subtitle': ?subtitle,
          'link_url': ?linkUrl,
          'cta_label': ?ctaLabel,
          if (sortOrder != null) 'sort_order': sortOrder.toString(),
          if (isActive != null) 'is_active': isActive ? '1' : '0',
          'image': await MultipartFile.fromFile(imagePath),
        }),
      );
      return AdminBanner.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// All fields optional — the old image is auto-deleted server-side when a
  /// new one is sent. Sent as multipart POST + `_method=PUT` (Laravel's
  /// standard method-spoofing for multipart bodies, since PUT can't carry
  /// multipart form data on most clients/servers).
  Future<AdminBanner> update(
    int id, {
    String? title,
    String? subtitle,
    String? linkUrl,
    String? ctaLabel,
    int? sortOrder,
    bool? isActive,
    String? imagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/banners/$id',
        data: FormData.fromMap({
          '_method': 'PUT',
          'title': ?title,
          'subtitle': ?subtitle,
          'link_url': ?linkUrl,
          'cta_label': ?ctaLabel,
          if (sortOrder != null) 'sort_order': sortOrder.toString(),
          if (isActive != null) 'is_active': isActive ? '1' : '0',
          if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
        }),
      );
      return AdminBanner.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/banners/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

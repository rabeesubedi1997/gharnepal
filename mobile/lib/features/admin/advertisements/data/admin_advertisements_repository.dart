import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_advertisement.dart';

/// Talks to `/admin/advertisements` — targeted ad slots by placement. Not
/// paginated, ordered by placement then `sort_order`. There is no
/// bulk-reorder endpoint — "move up/down" means two [update] calls swapping
/// two rows' `sort_order` values (within the same placement group).
class AdminAdvertisementsRepository {
  AdminAdvertisementsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AdminAdvertisement>> list() async {
    try {
      final response = await _dio.get('/admin/advertisements');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AdminAdvertisement.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AdminAdvertisement> create({
    String? title,
    String? subtitle,
    String? linkUrl,
    String? ctaLabel,
    required String placement,
    int? sortOrder,
    bool? isActive,
    required String imagePath,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/advertisements',
        data: FormData.fromMap({
          'title': ?title,
          'subtitle': ?subtitle,
          'link_url': ?linkUrl,
          'cta_label': ?ctaLabel,
          'placement': placement,
          if (sortOrder != null) 'sort_order': sortOrder.toString(),
          if (isActive != null) 'is_active': isActive ? '1' : '0',
          'image': await MultipartFile.fromFile(imagePath),
        }),
      );
      return AdminAdvertisement.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `placement` is immutable after creation and deliberately not accepted
  /// here. Sent as multipart POST + `_method=PUT`.
  Future<AdminAdvertisement> update(
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
        '/admin/advertisements/$id',
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
      return AdminAdvertisement.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/advertisements/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

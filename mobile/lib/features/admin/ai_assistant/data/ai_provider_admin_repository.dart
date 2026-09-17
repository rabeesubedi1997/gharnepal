import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/admin_ai_provider.dart';
import 'models/ai_provider_catalog_entry.dart';

/// Talks to `/admin/ai-providers` — the admin CRUD for every AI agent that
/// can drive the property-search assistant (see
/// backend/app/Http/Controllers/Api/V1/Admin/AiProviderConfigController.php).
/// Any number of configs may exist side by side; only one may be enabled at
/// a time, which the backend enforces and reports back via
/// `AiProviderMutationResult.disabledOthers`.
class AiProviderAdminRepository {
  AiProviderAdminRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<List<AiProviderCatalogEntry>> catalog() async {
    try {
      final response = await _dio.get('/admin/ai-providers/catalog');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AiProviderCatalogEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<AdminAiProvider>> list() async {
    try {
      final response = await _dio.get('/admin/ai-providers');
      return (response.data['data'] as List<dynamic>)
          .map((e) => AdminAiProvider.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<AiProviderMutationResult> create({
    required String provider,
    required String label,
    bool isEnabled = false,
    Map<String, String> credentials = const {},
  }) async {
    try {
      final response = await _dio.post(
        '/admin/ai-providers',
        data: {'provider': provider, 'label': label, 'is_enabled': isEnabled, 'credentials': credentials},
      );
      return _mutationResultFrom(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Every param optional — pass only what changed. `credentials` merges
  /// into what's already stored (a blank field keeps its current value),
  /// never replaces the whole set.
  Future<AiProviderMutationResult> update(int id, {String? label, bool? isEnabled, Map<String, String>? credentials}) async {
    try {
      final response = await _dio.put(
        '/admin/ai-providers/$id',
        data: {'label': ?label, 'is_enabled': ?isEnabled, 'credentials': ?credentials},
      );
      return _mutationResultFrom(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/ai-providers/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  AiProviderMutationResult _mutationResultFrom(Map<String, dynamic> body) {
    final meta = body['meta'] as Map<String, dynamic>?;
    final disabledOthers = (meta?['disabled_others'] as List<dynamic>? ?? [])
        .map((e) => DisabledOtherProvider.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return AiProviderMutationResult(config: AdminAiProvider.fromJson(body['data'] as Map<String, dynamic>), disabledOthers: disabledOthers);
  }
}

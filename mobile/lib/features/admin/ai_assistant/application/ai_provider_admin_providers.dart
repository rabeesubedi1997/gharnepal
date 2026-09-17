import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/ai_provider_admin_repository.dart';
import '../data/models/admin_ai_provider.dart';
import '../data/models/ai_provider_catalog_entry.dart';

final aiProviderAdminRepositoryProvider = Provider<AiProviderAdminRepository>((ref) {
  return AiProviderAdminRepository(apiClient: ref.watch(apiClientProvider));
});

/// Static-ish — the built-in provider list only changes with a deploy
/// (though an admin can always add another 'custom' agent without one).
final aiProviderCatalogProvider = FutureProvider<List<AiProviderCatalogEntry>>((ref) {
  return ref.watch(aiProviderAdminRepositoryProvider).catalog();
});

final adminAiProvidersProvider = FutureProvider.autoDispose<List<AdminAiProvider>>((ref) {
  return ref.watch(aiProviderAdminRepositoryProvider).list();
});

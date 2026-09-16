import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/branding_repository.dart';
import '../data/models/branding.dart';

final brandingRepositoryProvider = Provider<BrandingRepository>((ref) {
  return BrandingRepository(apiClient: ref.watch(apiClientProvider));
});

/// Rarely changes — an admin editing it is a deliberate, occasional action,
/// not something that needs re-fetching on every screen visit.
final brandingProvider = FutureProvider<Branding>((ref) {
  return ref.watch(brandingRepositoryProvider).get();
});

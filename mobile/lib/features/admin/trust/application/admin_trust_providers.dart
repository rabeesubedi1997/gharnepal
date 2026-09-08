import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_trust_repository.dart';
import '../data/models/trust_score_factor.dart';

final adminTrustRepositoryProvider = Provider<AdminTrustRepository>((ref) {
  return AdminTrustRepository(apiClient: ref.watch(apiClientProvider));
});

final adminTrustFactorsProvider = FutureProvider.autoDispose<List<TrustScoreFactor>>((ref) {
  return ref.read(adminTrustRepositoryProvider).factors();
});

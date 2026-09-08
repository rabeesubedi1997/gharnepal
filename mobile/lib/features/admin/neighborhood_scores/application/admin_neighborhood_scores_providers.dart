import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../data/admin_neighborhood_scores_repository.dart';

/// The picker list (`neighborhoodsListProvider`) and profile detail
/// (`neighborhoodProfileProvider`) are reused directly from
/// `lib/features/neighborhoods/application/neighborhoods_providers.dart` —
/// see the admin screen's imports. Only the admin-only writes get their own
/// repository/provider here.
final adminNeighborhoodScoresRepositoryProvider = Provider<AdminNeighborhoodScoresRepository>((ref) {
  return AdminNeighborhoodScoresRepository(apiClient: ref.watch(apiClientProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/viewing_request.dart';
import '../data/viewing_requests_repository.dart';

final viewingRequestsRepositoryProvider = Provider<ViewingRequestsRepository>((ref) {
  return ViewingRequestsRepository(apiClient: ref.watch(apiClientProvider));
});

/// One page (20, the backend's fixed page size) per tab — "My requests" vs
/// "Requests for my listings" — plenty for how this screen is actually used.
final viewingRequestsProvider = FutureProvider.autoDispose.family<List<ViewingRequest>, String>((ref, as) async {
  final result = await ref.watch(viewingRequestsRepositoryProvider).list(as: as);
  return result.items;
});

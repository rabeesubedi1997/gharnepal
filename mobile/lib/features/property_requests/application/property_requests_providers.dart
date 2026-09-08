import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/models/property_request.dart';
import '../data/property_requests_repository.dart';

final propertyRequestsRepositoryProvider = Provider<PropertyRequestsRepository>((ref) {
  return PropertyRequestsRepository(apiClient: ref.watch(apiClientProvider));
});

/// The public demand-side board — first page (15, the backend's fixed page
/// size) is enough for how this board is actually browsed.
final propertyRequestsBoardProvider = FutureProvider.autoDispose<List<PropertyRequest>>((ref) async {
  final result = await ref.watch(propertyRequestsRepositoryProvider).board();
  return result.items;
});

final myPropertyRequestsProvider = FutureProvider.autoDispose<List<PropertyRequest>>((ref) async {
  final result = await ref.watch(propertyRequestsRepositoryProvider).mine();
  return result.items;
});

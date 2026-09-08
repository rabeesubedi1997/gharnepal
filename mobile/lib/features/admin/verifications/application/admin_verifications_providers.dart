import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_verifications_repository.dart';
import '../data/models/admin_user_verification.dart';

final adminVerificationsRepositoryProvider = Provider<AdminVerificationsRepository>((ref) {
  return AdminVerificationsRepository(apiClient: ref.watch(apiClientProvider));
});

/// The selected status filter, defaulting to `pending` (the queue an admin
/// works from day to day).
final adminVerificationsStatusProvider = StateProvider.autoDispose<String>((ref) => 'pending');

/// The current page of the manual Previous/Next pager, matching the
/// website's own paging UI (no infinite scroll on admin lists).
final adminVerificationsPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final adminVerificationsProvider = FutureProvider.autoDispose<PaginatedResult<AdminUserVerification>>((ref) {
  final status = ref.watch(adminVerificationsStatusProvider);
  final page = ref.watch(adminVerificationsPageProvider);
  return ref.read(adminVerificationsRepositoryProvider).list(status: status, page: page);
});

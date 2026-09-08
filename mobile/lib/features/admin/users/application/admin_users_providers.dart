import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_result.dart';
import '../../../../core/network/providers.dart';
import '../data/admin_users_repository.dart';
import '../data/models/admin_user.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(apiClient: ref.watch(apiClientProvider));
});

/// Filter/paging state for the users list — mirrors the blog screen's
/// Previous/Next pager, with search + role + status filters added. Any
/// filter change should reset [adminUsersPageProvider] back to 1.
final adminUsersSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final adminUsersRoleFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final adminUsersStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final adminUsersPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final adminUsersListProvider = FutureProvider.autoDispose<PaginatedResult<AdminUser>>((ref) {
  final q = ref.watch(adminUsersSearchProvider);
  final role = ref.watch(adminUsersRoleFilterProvider);
  final status = ref.watch(adminUsersStatusFilterProvider);
  final page = ref.watch(adminUsersPageProvider);
  return ref.read(adminUsersRepositoryProvider).list(q: q, role: role, status: status, page: page);
});

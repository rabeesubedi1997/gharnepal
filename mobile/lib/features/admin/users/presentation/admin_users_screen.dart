import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../auth/application/auth_controller.dart';
import '../application/admin_users_providers.dart';
import '../data/models/admin_user.dart';

/// Admin users list: `GET /admin/users` with search + role + status filters,
/// a manual Previous/Next pager (mirrors the blog screen), and a tap-to-edit
/// bottom sheet for status/roles.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetToFirstPage() => ref.read(adminUsersPageProvider.notifier).state = 1;

  BadgeTone _statusTone(String status) => switch (status) {
    'active' => BadgeTone.success,
    'suspended' => BadgeTone.danger,
    _ => BadgeTone.warning, // pending
  };

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersListProvider);
    final page = ref.watch(adminUsersPageProvider);
    final role = ref.watch(adminUsersRoleFilterProvider);
    final status = ref.watch(adminUsersStatusFilterProvider);
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Name, email, or phone',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref.read(adminUsersSearchProvider.notifier).state = value.trim();
                _resetToFirstPage();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All roles')),
                      for (final r in kAdminUserRoles) DropdownMenuItem(value: r, child: Text(r)),
                    ],
                    onChanged: (value) {
                      ref.read(adminUsersRoleFilterProvider.notifier).state = value;
                      _resetToFirstPage();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All statuses')),
                      for (final s in kAdminUserStatuses) DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (value) {
                      ref.read(adminUsersStatusFilterProvider.notifier).state = value;
                      _resetToFirstPage();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load users.',
                onRetry: () => ref.invalidate(adminUsersListProvider),
              ),
              data: (result) => result.items.isEmpty
                  ? const EmptyState(title: 'No users found', icon: Icons.people_outline)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: result.items.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = result.items[index];
                              return _UserCard(
                                user: user,
                                statusTone: _statusTone(user.status),
                                isSelf: user.id == currentUserId,
                              );
                            },
                          ),
                        ),
                        if (result.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: page > 1
                                      ? () => ref.read(adminUsersPageProvider.notifier).state = page - 1
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                Text('Page $page of ${result.lastPage}'),
                                TextButton(
                                  onPressed: page < result.lastPage
                                      ? () => ref.read(adminUsersPageProvider.notifier).state = page + 1
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.statusTone, required this.isSelf});

  final AdminUser user;
  final BadgeTone statusTone;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _UserEditSheet.show(context, user, isSelf: isSelf),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                  ),
                  AppBadge(label: user.status, tone: statusTone),
                ],
              ),
              const SizedBox(height: 4),
              Text(user.email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
              if (user.phone != null)
                Text(user.phone!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final role in user.roles) AppBadge(label: role, tone: BadgeTone.trust),
                  for (final agency in user.agencies) AppBadge(label: agency, tone: BadgeTone.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserEditSheet extends ConsumerStatefulWidget {
  const _UserEditSheet({required this.user, required this.isSelf});

  final AdminUser user;
  final bool isSelf;

  static Future<void> show(BuildContext context, AdminUser user, {required bool isSelf}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserEditSheet(user: user, isSelf: isSelf),
    );
  }

  @override
  ConsumerState<_UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends ConsumerState<_UserEditSheet> {
  late final Set<String> _selectedRoles = widget.user.roles.toSet();
  bool _statusBusy = false;
  bool _rolesBusy = false;

  Future<void> _toggleStatus() async {
    final nextStatus = widget.user.status == 'suspended' ? 'active' : 'suspended';
    setState(() => _statusBusy = true);
    try {
      await ref.read(adminUsersRepositoryProvider).updateStatus(widget.user.id, nextStatus);
      ref.invalidate(adminUsersListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _saveRoles() async {
    setState(() => _rolesBusy = true);
    try {
      await ref.read(adminUsersRepositoryProvider).updateRoles(widget.user.id, _selectedRoles.toList());
      ref.invalidate(adminUsersListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _rolesBusy = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final busy = _statusBusy || _rolesBusy;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.titleMedium),
            Text(user.email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
            const SizedBox(height: 16),
            if (!widget.isSelf) ...[
              Text('Status: ${user.status}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              AppButton(
                label: user.status == 'suspended' ? 'Activate' : 'Suspend',
                variant: AppButtonVariant.outlined,
                isLoading: _statusBusy,
                onPressed: busy ? null : _toggleStatus,
              ),
              const SizedBox(height: 20),
            ],
            Text('Roles', style: Theme.of(context).textTheme.titleSmall),
            for (final role in kAdminUserRoles)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(role),
                value: _selectedRoles.contains(role),
                onChanged: busy
                    ? null
                    : (checked) => setState(() {
                        if (checked ?? false) {
                          _selectedRoles.add(role);
                        } else {
                          _selectedRoles.remove(role);
                        }
                      }),
              ),
            const SizedBox(height: 12),
            AppButton(label: 'Save roles', isLoading: _rolesBusy, onPressed: busy ? null : _saveRoles),
          ],
        ),
      ),
    );
  }
}

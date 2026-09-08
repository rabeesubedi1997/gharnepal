import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_bottom_nav.dart';
import '../../auth/application/auth_controller.dart';

/// A simple menu hub for destinations that don't fit the bottom nav —
/// mirrors the account-area links scattered across the website's header
/// and Dashboard. Settings/profile editing lands in a later phase.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Center(
          child: FilledButton(onPressed: () => context.push('/login'), child: const Text('Log in')),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.trust100,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.trust700, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.request_quote_outlined),
            title: const Text('Property requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/property-requests'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Viewing requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/viewing-requests'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger600),
            title: const Text('Log out', style: TextStyle(color: AppColors.danger600)),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

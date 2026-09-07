import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../auth/application/auth_controller.dart';

/// Placeholder proving the foundation end-to-end (auth, theme, router, API
/// client all wired to the live backend). The real Home — banners, browse-
/// by-city, search entry point — is built in Phase 2.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Ghar Nepal')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success600, size: 40),
              const SizedBox(height: 12),
              Text('Signed in', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (user != null) ...[
                Text(user.name, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.ink700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: user.roles
                      .map((role) => AppBadge(label: role, tone: BadgeTone.trust))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Log out',
                variant: AppButtonVariant.outlined,
                expand: false,
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

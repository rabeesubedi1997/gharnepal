import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_banners_providers.dart';
import '../data/models/admin_banner.dart';
import 'banner_form_dialog.dart';

/// Homepage hero-slider CMS. Not paginated — a flat list ordered by
/// `sort_order`, with manual up/down reordering (two swapped PUT calls,
/// there's no bulk-reorder endpoint).
class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  Future<void> _toggleActive(WidgetRef ref, BuildContext context, AdminBanner banner, bool value) async {
    try {
      await ref.read(adminBannersRepositoryProvider).update(banner.id, isActive: value);
      ref.invalidate(adminBannersListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not update the banner.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _move(WidgetRef ref, BuildContext context, List<AdminBanner> items, int index, int delta) async {
    final otherIndex = index + delta;
    if (otherIndex < 0 || otherIndex >= items.length) return;
    final a = items[index];
    final b = items[otherIndex];
    try {
      final repo = ref.read(adminBannersRepositoryProvider);
      await repo.update(a.id, sortOrder: b.sortOrder);
      await repo.update(b.id, sortOrder: a.sortOrder);
      ref.invalidate(adminBannersListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not reorder banners.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _delete(WidgetRef ref, BuildContext context, AdminBanner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this banner?'),
        content: Text(banner.title ?? 'This banner will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminBannersRepositoryProvider).delete(banner.id);
      ref.invalidate(adminBannersListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not delete the banner.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(adminBannersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Banners')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BannerFormDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add banner'),
      ),
      body: banners.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            4,
            (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 100)),
          ),
        ),
        error: (error, _) =>
            ErrorState(message: 'Could not load banners.', onRetry: () => ref.invalidate(adminBannersListProvider)),
        data: (items) => items.isEmpty
            ? const EmptyState(title: 'No banners yet', icon: Icons.view_carousel_outlined)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminBannersListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _BannerCard(
                    banner: items[index],
                    canMoveUp: index > 0,
                    canMoveDown: index < items.length - 1,
                    onToggleActive: (value) => _toggleActive(ref, context, items[index], value),
                    onMoveUp: () => _move(ref, context, items, index, -1),
                    onMoveDown: () => _move(ref, context, items, index, 1),
                    onEdit: () => BannerFormDialog.show(context, banner: items[index]),
                    onDelete: () => _delete(ref, context, items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggleActive,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminBanner banner;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: banner.imageUrl, width: 72, height: 72, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(banner.title ?? '(untitled)', style: Theme.of(context).textTheme.titleSmall),
                  if (banner.subtitle != null)
                    Text(banner.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      IconButton(
                        onPressed: canMoveUp ? onMoveUp : null,
                        icon: const Icon(Icons.arrow_upward),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: canMoveDown ? onMoveDown : null,
                        icon: const Icon(Icons.arrow_downward),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(value: banner.isActive, onChanged: onToggleActive),
          ],
        ),
      ),
    );
  }
}

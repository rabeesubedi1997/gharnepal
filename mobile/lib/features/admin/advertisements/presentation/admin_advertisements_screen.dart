import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_advertisements_providers.dart';
import '../data/models/ad_placement.dart';
import '../data/models/admin_advertisement.dart';
import 'advertisement_form_dialog.dart';

/// Targeted ad slots CMS, grouped into 3 sections — one per `AdPlacement`
/// key — each its own ordered sub-list.
class AdminAdvertisementsScreen extends ConsumerWidget {
  const AdminAdvertisementsScreen({super.key});

  Future<void> _toggleActive(WidgetRef ref, BuildContext context, AdminAdvertisement ad, bool value) async {
    try {
      await ref.read(adminAdvertisementsRepositoryProvider).update(ad.id, isActive: value);
      ref.invalidate(adminAdvertisementsListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not update the advertisement.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _move(
    WidgetRef ref,
    BuildContext context,
    List<AdminAdvertisement> group,
    int index,
    int delta,
  ) async {
    final otherIndex = index + delta;
    if (otherIndex < 0 || otherIndex >= group.length) return;
    final a = group[index];
    final b = group[otherIndex];
    try {
      final repo = ref.read(adminAdvertisementsRepositoryProvider);
      await repo.update(a.id, sortOrder: b.sortOrder);
      await repo.update(b.id, sortOrder: a.sortOrder);
      ref.invalidate(adminAdvertisementsListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not reorder advertisements.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _delete(WidgetRef ref, BuildContext context, AdminAdvertisement ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this advertisement?'),
        content: Text(ad.title ?? 'This advertisement will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminAdvertisementsRepositoryProvider).delete(ad.id);
      ref.invalidate(adminAdvertisementsListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not delete the advertisement.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(adminAdvertisementsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Advertisements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AdvertisementFormDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add advertisement'),
      ),
      body: ads.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            4,
            (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 100)),
          ),
        ),
        error: (error, _) => ErrorState(
          message: 'Could not load advertisements.',
          onRetry: () => ref.invalidate(adminAdvertisementsListProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(title: 'No advertisements yet', icon: Icons.campaign_outlined)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminAdvertisementsListProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  children: [
                    for (final placement in AdPlacement.values)
                      _PlacementSection(
                        placement: placement,
                        items: items.where((ad) => ad.placement == placement).toList(),
                        onAdd: () => AdvertisementFormDialog.show(context, initialPlacement: placement),
                        onToggleActive: (ad, value) => _toggleActive(ref, context, ad, value),
                        onMove: (group, index, delta) => _move(ref, context, group, index, delta),
                        onEdit: (ad) => AdvertisementFormDialog.show(context, advertisement: ad),
                        onDelete: (ad) => _delete(ref, context, ad),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PlacementSection extends StatelessWidget {
  const _PlacementSection({
    required this.placement,
    required this.items,
    required this.onAdd,
    required this.onToggleActive,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
  });

  final String placement;
  final List<AdminAdvertisement> items;
  final VoidCallback onAdd;
  final void Function(AdminAdvertisement ad, bool value) onToggleActive;
  final void Function(List<AdminAdvertisement> group, int index, int delta) onMove;
  final void Function(AdminAdvertisement ad) onEdit;
  final void Function(AdminAdvertisement ad) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AdPlacement.label(placement), style: Theme.of(context).textTheme.titleMedium),
              ),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No ads in this slot.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
            )
          else
            ...items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdCard(
                  ad: entry.value,
                  canMoveUp: entry.key > 0,
                  canMoveDown: entry.key < items.length - 1,
                  onToggleActive: (value) => onToggleActive(entry.value, value),
                  onMoveUp: () => onMove(items, entry.key, -1),
                  onMoveDown: () => onMove(items, entry.key, 1),
                  onEdit: () => onEdit(entry.value),
                  onDelete: () => onDelete(entry.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.ad,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggleActive,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminAdvertisement ad;
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
              child: CachedNetworkImage(imageUrl: ad.imageUrl, width: 72, height: 72, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad.title ?? '(untitled)', style: Theme.of(context).textTheme.titleSmall),
                  if (ad.subtitle != null) Text(ad.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
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
            Switch(value: ad.isActive, onChanged: onToggleActive),
          ],
        ),
      ),
    );
  }
}

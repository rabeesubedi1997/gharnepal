import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_amenities_providers.dart';
import '../data/models/admin_amenity.dart';
import 'amenity_form_dialog.dart';

/// Admin CRUD for the shared amenities reference list — grouped by category
/// since that's how they're already presented to a buyer filtering search
/// and to an owner in the post-property wizard.
class AdminAmenitiesScreen extends ConsumerWidget {
  const AdminAmenitiesScreen({super.key});

  Future<void> _delete(WidgetRef ref, BuildContext context, AdminAmenity amenity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this amenity?'),
        content: Text('"${amenity.name}" will be removed. Listings that had it selected will lose it.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminAmenitiesRepositoryProvider).delete(amenity.id);
      ref.invalidate(adminAmenitiesListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not delete the amenity.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenities = ref.watch(adminAmenitiesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Amenities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AmenityFormDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add amenity'),
      ),
      body: amenities.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            6,
            (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: Skeleton(height: 56)),
          ),
        ),
        error: (error, _) => ErrorState(
          message: 'Could not load amenities.',
          onRetry: () => ref.invalidate(adminAmenitiesListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'No amenities yet', icon: Icons.list_alt_outlined);
          }

          final byCategory = <String, List<AdminAmenity>>{};
          for (final amenity in items) {
            byCategory.putIfAbsent(amenity.category ?? 'Other', () => []).add(amenity);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminAmenitiesListProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              children: [
                for (final entry in byCategory.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Text(entry.key, style: Theme.of(context).textTheme.labelLarge),
                  ),
                  for (final amenity in entry.value)
                    Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        title: Text(amenity.name),
                        subtitle: Text(amenity.nameNe != null ? '${amenity.key} · ${amenity.nameNe}' : amenity.key),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => AmenityFormDialog.show(context, amenity: amenity),
                              icon: const Icon(Icons.edit_outlined),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              onPressed: () => _delete(ref, context, amenity),
                              icon: const Icon(Icons.delete_outline),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../widgets/app_button.dart';
import '../application/admin_amenities_providers.dart';
import '../data/models/admin_amenity.dart';

/// Create/edit form for a single amenity. `key` is the only field an admin
/// can't leave blank on create (it's the stable identifier other code — the
/// search filter, the wizard's checkbox list — actually keys off), matching
/// the backend's `required|alpha_dash|unique` validation on that field.
class AmenityFormDialog extends ConsumerStatefulWidget {
  const AmenityFormDialog({super.key, this.amenity});

  final AdminAmenity? amenity;

  static Future<void> show(BuildContext context, {AdminAmenity? amenity}) {
    return showDialog(context: context, builder: (context) => AmenityFormDialog(amenity: amenity));
  }

  @override
  ConsumerState<AmenityFormDialog> createState() => _AmenityFormDialogState();
}

class _AmenityFormDialogState extends ConsumerState<AmenityFormDialog> {
  late final _keyController = TextEditingController(text: widget.amenity?.key);
  late final _nameController = TextEditingController(text: widget.amenity?.name);
  late final _nameNeController = TextEditingController(text: widget.amenity?.nameNe);
  late final _categoryController = TextEditingController(text: widget.amenity?.category);
  late final _iconController = TextEditingController(text: widget.amenity?.icon);

  bool _saving = false;

  bool get _isEditing => widget.amenity != null;

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _nameNeController.dispose();
    _categoryController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  String? _blankToNull(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _save() async {
    if (_keyController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key and name are both required.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(adminAmenitiesRepositoryProvider);
      if (_isEditing) {
        await repo.update(
          widget.amenity!.id,
          key: _keyController.text.trim(),
          name: _nameController.text.trim(),
          nameNe: _blankToNull(_nameNeController.text),
          category: _blankToNull(_categoryController.text),
          icon: _blankToNull(_iconController.text),
        );
      } else {
        await repo.create(
          key: _keyController.text.trim(),
          name: _nameController.text.trim(),
          nameNe: _blankToNull(_nameNeController.text),
          category: _blankToNull(_categoryController.text),
          icon: _blankToNull(_iconController.text),
        );
      }
      ref.invalidate(adminAmenitiesListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Could not save the amenity.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit amenity' : 'Add amenity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(labelText: 'Key', hintText: 'e.g. wifi, parking, lift'),
            ),
            const SizedBox(height: 8),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: _nameNeController, decoration: const InputDecoration(labelText: 'Name (Nepali)')),
            const SizedBox(height: 8),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 8),
            TextField(controller: _iconController, decoration: const InputDecoration(labelText: 'Icon')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        AppButton(label: 'Save', expand: false, isLoading: _saving, onPressed: _save),
      ],
    );
  }
}

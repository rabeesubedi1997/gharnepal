import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../listings/data/models/search_filters.dart';
import '../application/saved_searches_providers.dart';

/// A small "name this search" prompt, invoked from the Search screen's
/// bookmark action — mirrors the web's "Save search" modal.
class SaveSearchDialog extends ConsumerStatefulWidget {
  const SaveSearchDialog({super.key, required this.filters});

  final SearchFilters filters;

  static Future<bool?> show(BuildContext context, SearchFilters filters) {
    return showDialog<bool>(context: context, builder: (context) => SaveSearchDialog(filters: filters));
  }

  @override
  ConsumerState<SaveSearchDialog> createState() => _SaveSearchDialogState();
}

class _SaveSearchDialogState extends ConsumerState<SaveSearchDialog> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(savedSearchesRepositoryProvider).create(name: name, filters: widget.filters);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save this search'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. 2BHK in Kathmandu under 30K'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

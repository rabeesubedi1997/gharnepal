import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../application/admin_advertisements_providers.dart';
import '../data/models/ad_placement.dart';
import '../data/models/admin_advertisement.dart';

/// Create/edit form for a single advertisement. `placement` is chosen via a
/// dropdown on create only — immutable afterwards, so the edit form omits it.
class AdvertisementFormDialog extends ConsumerStatefulWidget {
  const AdvertisementFormDialog({super.key, this.advertisement, this.initialPlacement});

  final AdminAdvertisement? advertisement;

  /// Pre-selects the placement when adding from within a specific section.
  final String? initialPlacement;

  static Future<void> show(BuildContext context, {AdminAdvertisement? advertisement, String? initialPlacement}) {
    return showDialog(
      context: context,
      builder: (context) => AdvertisementFormDialog(advertisement: advertisement, initialPlacement: initialPlacement),
    );
  }

  @override
  ConsumerState<AdvertisementFormDialog> createState() => _AdvertisementFormDialogState();
}

class _AdvertisementFormDialogState extends ConsumerState<AdvertisementFormDialog> {
  late final _titleController = TextEditingController(text: widget.advertisement?.title);
  late final _subtitleController = TextEditingController(text: widget.advertisement?.subtitle);
  late final _linkUrlController = TextEditingController(text: widget.advertisement?.linkUrl);
  late final _ctaLabelController = TextEditingController(text: widget.advertisement?.ctaLabel);
  late String _placement =
      widget.advertisement?.placement ?? widget.initialPlacement ?? AdPlacement.values.first;

  XFile? _newImage;
  bool _saving = false;

  bool get _isEditing => widget.advertisement != null;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkUrlController.dispose();
    _ctaLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) setState(() => _newImage = picked);
  }

  Future<void> _save() async {
    if (!_isEditing && _newImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose an image.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(adminAdvertisementsRepositoryProvider);
      if (_isEditing) {
        await repo.update(
          widget.advertisement!.id,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
          linkUrl: _linkUrlController.text.trim().isEmpty ? null : _linkUrlController.text.trim(),
          ctaLabel: _ctaLabelController.text.trim().isEmpty ? null : _ctaLabelController.text.trim(),
          imagePath: _newImage?.path,
        );
      } else {
        await repo.create(
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
          linkUrl: _linkUrlController.text.trim().isEmpty ? null : _linkUrlController.text.trim(),
          ctaLabel: _ctaLabelController.text.trim().isEmpty ? null : _ctaLabelController.text.trim(),
          placement: _placement,
          imagePath: _newImage!.path,
        );
      }
      ref.invalidate(adminAdvertisementsListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Could not save the advertisement.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit advertisement' : 'Add advertisement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePreview(newImage: _newImage, existingUrl: widget.advertisement?.imageUrl, onPick: _pickImage),
            const SizedBox(height: 12),
            if (!_isEditing) ...[
              DropdownButtonFormField<String>(
                initialValue: _placement,
                decoration: const InputDecoration(labelText: 'Placement'),
                items: [
                  for (final key in AdPlacement.values) DropdownMenuItem(value: key, child: Text(AdPlacement.label(key))),
                ],
                onChanged: (value) => setState(() => _placement = value ?? _placement),
              ),
              const SizedBox(height: 8),
            ],
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(
              controller: _subtitleController,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Subtitle'),
            ),
            TextField(controller: _linkUrlController, decoration: const InputDecoration(labelText: 'Link URL')),
            const SizedBox(height: 8),
            TextField(
              controller: _ctaLabelController,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'CTA label'),
            ),
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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.newImage, required this.existingUrl, required this.onPick});

  final XFile? newImage;
  final String? existingUrl;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.stone100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.stone200),
        ),
        clipBehavior: Clip.antiAlias,
        child: newImage != null
            ? Image.file(File(newImage!.path), fit: BoxFit.cover, width: double.infinity)
            : existingUrl != null
            ? CachedNetworkImage(imageUrl: existingUrl!, fit: BoxFit.cover, width: double.infinity)
            : const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 32)),
      ),
    );
  }
}

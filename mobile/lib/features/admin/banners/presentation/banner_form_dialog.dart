import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../application/admin_banners_providers.dart';
import '../data/models/admin_banner.dart';

/// Create/edit form for a single banner. Image is required on create,
/// optional on edit (keeps the current image if none is picked).
class BannerFormDialog extends ConsumerStatefulWidget {
  const BannerFormDialog({super.key, this.banner});

  final AdminBanner? banner;

  static Future<void> show(BuildContext context, {AdminBanner? banner}) {
    return showDialog(context: context, builder: (context) => BannerFormDialog(banner: banner));
  }

  @override
  ConsumerState<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<BannerFormDialog> {
  late final _titleController = TextEditingController(text: widget.banner?.title);
  late final _subtitleController = TextEditingController(text: widget.banner?.subtitle);
  late final _linkUrlController = TextEditingController(text: widget.banner?.linkUrl);
  late final _ctaLabelController = TextEditingController(text: widget.banner?.ctaLabel);

  XFile? _newImage;
  bool _saving = false;

  bool get _isEditing => widget.banner != null;

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
      final repo = ref.read(adminBannersRepositoryProvider);
      if (_isEditing) {
        await repo.update(
          widget.banner!.id,
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
          imagePath: _newImage!.path,
        );
      }
      ref.invalidate(adminBannersListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Could not save the banner.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit banner' : 'Add banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePreview(newImage: _newImage, existingUrl: widget.banner?.imageUrl, onPick: _pickImage),
            const SizedBox(height: 12),
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

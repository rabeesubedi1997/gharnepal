import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_blog_providers.dart';
import '../data/models/admin_blog_post.dart';

/// Create/edit form — the same widget for both, distinguished only by
/// whether [postId] is null. "Save as draft" and "Publish" both call the
/// same submit method, differing only in the `status` value sent.
class AdminBlogEditorScreen extends ConsumerStatefulWidget {
  const AdminBlogEditorScreen({super.key, this.postId});

  final int? postId;

  @override
  ConsumerState<AdminBlogEditorScreen> createState() => _AdminBlogEditorScreenState();
}

class _AdminBlogEditorScreenState extends ConsumerState<AdminBlogEditorScreen> {
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _bodyController = TextEditingController();

  XFile? _newCoverImage;
  String? _existingCoverImageUrl;
  bool _initialized = false;
  bool _saving = false;

  bool get _isEditing => widget.postId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _populateFrom(AdminBlogPost post) {
    _titleController.text = post.title;
    _excerptController.text = post.excerpt ?? '';
    _bodyController.text = post.body;
    _existingCoverImageUrl = post.coverImageUrl;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) setState(() => _newCoverImage = picked);
  }

  Future<void> _submit(String status) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body are required.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(adminBlogRepositoryProvider);
      final excerpt = _excerptController.text.trim();
      if (_isEditing) {
        await repo.update(
          widget.postId!,
          title: title,
          excerpt: excerpt.isEmpty ? null : excerpt,
          body: body,
          status: status,
          coverImagePath: _newCoverImage?.path,
        );
      } else {
        await repo.create(
          title: title,
          excerpt: excerpt.isEmpty ? null : excerpt,
          body: body,
          status: status,
          coverImagePath: _newCoverImage?.path,
        );
      }
      ref.invalidate(adminBlogListProvider);
      if (widget.postId != null) ref.invalidate(adminBlogPostProvider(widget.postId!));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Could not save this post.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('New post')),
        body: _buildForm(context),
      );
    }

    final post = ref.watch(adminBlogPostProvider(widget.postId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit post')),
      body: post.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load this post.',
          onRetry: () => ref.invalidate(adminBlogPostProvider(widget.postId!)),
        ),
        data: (data) {
          if (!_initialized) {
            _populateFrom(data);
            _initialized = true;
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.stone200),
            ),
            clipBehavior: Clip.antiAlias,
            child: _newCoverImage != null
                ? Image.file(File(_newCoverImage!.path), fit: BoxFit.cover, width: double.infinity)
                : _existingCoverImageUrl != null
                ? CachedNetworkImage(imageUrl: _existingCoverImageUrl!, fit: BoxFit.cover, width: double.infinity)
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 32),
                        SizedBox(height: 4),
                        Text('Cover image (optional)'),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        TextField(
          controller: _excerptController,
          maxLength: 300,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Excerpt'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyController,
          minLines: 10,
          maxLines: 24,
          decoration: const InputDecoration(labelText: 'Body', alignLabelWithHint: true),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Publish',
          isLoading: _saving,
          onPressed: () => _submit('published'),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Save as draft',
          variant: AppButtonVariant.outlined,
          isLoading: _saving,
          onPressed: () => _submit('draft'),
        ),
      ],
    );
  }
}

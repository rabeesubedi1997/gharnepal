import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_blog_providers.dart';
import '../data/models/admin_blog_post.dart';

/// Blog CMS list — includes drafts, ordered newest-first. Tap a card to
/// edit; "New post" opens the editor in create mode.
class AdminBlogScreen extends ConsumerWidget {
  const AdminBlogScreen({super.key});

  static final _dateFormat = DateFormat('d MMM y');

  Future<void> _delete(WidgetRef ref, BuildContext context, AdminBlogPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this post?'),
        content: Text(post.title),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminBlogRepositoryProvider).delete(post.id);
      ref.invalidate(adminBlogListProvider);
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException ? error.message : 'Could not delete this post.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(adminBlogListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/blog/new'),
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
      body: posts.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            5,
            (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 84)),
          ),
        ),
        error: (error, _) =>
            ErrorState(message: 'Could not load blog posts.', onRetry: () => ref.invalidate(adminBlogListProvider)),
        data: (items) => items.isEmpty
            ? const EmptyState(title: 'No posts yet', icon: Icons.article_outlined)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminBlogListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: items.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _PostCard(
                    post: items[index],
                    dateFormat: _dateFormat,
                    onTap: () => context.push('/admin/blog/${items[index].id}/edit'),
                    onDelete: () => _delete(ref, context, items[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.dateFormat, required this.onTap, required this.onDelete});

  final AdminBlogPost post;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(post.title, style: Theme.of(context).textTheme.titleSmall)),
                  AppBadge(
                    label: post.status,
                    tone: post.status == 'published' ? BadgeTone.success : BadgeTone.neutral,
                  ),
                  IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
                ],
              ),
              Text(
                '${post.author}'
                '${post.publishedAt != null ? ' · ${dateFormat.format(DateTime.parse(post.publishedAt!))}' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

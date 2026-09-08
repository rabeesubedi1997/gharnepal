import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/blog_providers.dart';
import '../data/models/blog_post_summary.dart';

/// Mirrors frontend/src/pages/Blog/index.tsx: a card grid with a manual
/// Previous/Next pager (the backend paginates at a fixed 9/page).
class BlogScreen extends ConsumerWidget {
  const BlogScreen({super.key});

  static final _dateFormat = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(blogListProvider);
    final page = ref.watch(blogPageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load articles.',
          onRetry: () => ref.invalidate(blogListProvider),
        ),
        data: (result) => result.items.isEmpty
            ? const EmptyState(title: 'No articles yet', icon: Icons.newspaper_outlined)
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: result.items.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _PostCard(post: result.items[index], dateFormat: _dateFormat),
                    ),
                  ),
                  if (result.lastPage > 1)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: page > 1 ? () => ref.read(blogPageProvider.notifier).state = page - 1 : null,
                            child: const Text('Previous'),
                          ),
                          Text('Page $page of ${result.lastPage}'),
                          TextButton(
                            onPressed: page < result.lastPage
                                ? () => ref.read(blogPageProvider.notifier).state = page + 1
                                : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.dateFormat});

  final BlogPostSummary post;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/blog/${post.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: post.coverImageUrl != null
                  ? CachedNetworkImage(imageUrl: post.coverImageUrl!, fit: BoxFit.cover)
                  : Container(color: AppColors.stone200, child: const Icon(Icons.newspaper_outlined, size: 32)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: Theme.of(context).textTheme.titleMedium),
                  if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(post.excerpt!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${post.author ?? 'Ghar Nepal'}'
                    '${post.publishedAt != null ? ' · ${dateFormat.format(DateTime.parse(post.publishedAt!))}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

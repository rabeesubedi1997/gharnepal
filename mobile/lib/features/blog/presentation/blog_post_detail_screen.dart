import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/error_state.dart';
import '../application/blog_providers.dart';

/// Mirrors frontend/src/pages/Blog/BlogPostDetail.tsx: title, author/date,
/// optional cover image, then the plain-text body rendered with its
/// newlines preserved (no HTML/Markdown parsing — the backend guarantees
/// this is plain text).
class BlogPostDetailScreen extends ConsumerWidget {
  const BlogPostDetailScreen({super.key, required this.slug});

  final String slug;

  static final _dateFormat = DateFormat('d MMM y');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(blogPostProvider(slug));

    return Scaffold(
      appBar: AppBar(),
      body: post.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'This article may have been removed.',
          onRetry: () => ref.invalidate(blogPostProvider(slug)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(data.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${data.author ?? 'Ghar Nepal'}'
              '${data.publishedAt != null ? ' · ${_dateFormat.format(DateTime.parse(data.publishedAt!))}' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
            if (data.coverImageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(imageUrl: data.coverImageUrl!, fit: BoxFit.cover),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(data.body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

import 'blog_post_summary.dart';

/// Mirrors `BlogPostResource` — the summary shape plus `body`. The body is
/// **plain text**, not HTML/Markdown/rich blocks (only newlines matter,
/// same convention as listing descriptions) — render it verbatim in a
/// `Text`/`SelectableText`, never through an HTML or Markdown widget.
class BlogPost {
  BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.coverImageUrl,
    this.author,
    this.publishedAt,
    required this.body,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final summary = BlogPostSummary.fromJson(json);
    return BlogPost(
      id: summary.id,
      title: summary.title,
      slug: summary.slug,
      excerpt: summary.excerpt,
      coverImageUrl: summary.coverImageUrl,
      author: summary.author,
      publishedAt: summary.publishedAt,
      body: json['body'] as String? ?? '',
    );
  }

  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? coverImageUrl;
  final String? author;
  final String? publishedAt;
  final String body;
}

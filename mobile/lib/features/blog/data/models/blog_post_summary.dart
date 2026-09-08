import '../../../../core/network/media_url.dart';

/// Mirrors `BlogPostSummaryResource` — there's no category/tag taxonomy at
/// all server-side (confirmed: no columns, no filter params).
class BlogPostSummary {
  BlogPostSummary({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.coverImageUrl,
    this.author,
    this.publishedAt,
  });

  factory BlogPostSummary.fromJson(Map<String, dynamic> json) {
    return BlogPostSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      excerpt: json['excerpt'] as String?,
      coverImageUrl: json['cover_image_url'] != null ? resolveMediaUrl(json['cover_image_url'] as String) : null,
      author: json['author'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }

  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? coverImageUrl;
  final String? author;
  final String? publishedAt;
}

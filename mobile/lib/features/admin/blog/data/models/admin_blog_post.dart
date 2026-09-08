import '../../../../../core/network/json_parsing.dart';
import '../../../../../core/network/media_url.dart';

/// Mirrors `Admin\BlogPostResource` — the admin shape differs from the
/// consumer `BlogPostResource`: adds `status`/`updated_at`, `author` is a
/// plain string (not an object), and there's no excerpt truncation. Kept as
/// its own model rather than reusing `lib/features/blog/*` for that reason.
class AdminBlogPost {
  AdminBlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.body,
    this.coverImageUrl,
    required this.status,
    required this.author,
    this.publishedAt,
    required this.updatedAt,
  });

  factory AdminBlogPost.fromJson(Map<String, dynamic> json) {
    return AdminBlogPost(
      id: asInt(json['id'])!,
      title: json['title'] as String,
      slug: json['slug'] as String,
      excerpt: json['excerpt'] as String?,
      body: json['body'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] != null ? resolveMediaUrl(json['cover_image_url'] as String) : null,
      status: json['status'] as String,
      author: json['author'] as String,
      publishedAt: json['published_at'] as String?,
      updatedAt: json['updated_at'] as String,
    );
  }

  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String body;
  final String? coverImageUrl;
  final String status; // draft | published
  final String author;
  final String? publishedAt;
  final String updatedAt;
}

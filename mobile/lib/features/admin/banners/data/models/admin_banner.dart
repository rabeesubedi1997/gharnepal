import '../../../../../core/network/json_parsing.dart';
import '../../../../../core/network/media_url.dart';

/// Mirrors `BannerResource` — the homepage hero slider (a flat list, no
/// date range or placement concept, unlike Advertisements).
class AdminBanner {
  AdminBanner({
    required this.id,
    this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkUrl,
    this.ctaLabel,
    required this.sortOrder,
    required this.isActive,
  });

  factory AdminBanner.fromJson(Map<String, dynamic> json) {
    return AdminBanner(
      id: asInt(json['id'])!,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      imageUrl: resolveMediaUrl(json['image_url'] as String),
      linkUrl: json['link_url'] as String?,
      ctaLabel: json['cta_label'] as String?,
      sortOrder: asInt(json['sort_order']) ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int id;
  final String? title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String? ctaLabel;
  final int sortOrder;
  final bool isActive;
}

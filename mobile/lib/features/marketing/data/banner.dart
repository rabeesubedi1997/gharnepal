import '../../../core/network/media_url.dart';

/// Mirrors `BannerResource` — the homepage slider.
class AppBanner {
  AppBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkUrl,
    this.ctaLabel,
    required this.sortOrder,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    return AppBanner(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: resolveMediaUrl(json['image_url'] as String),
      linkUrl: json['link_url'] as String?,
      ctaLabel: json['cta_label'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  final int id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String? ctaLabel;
  final int sortOrder;
}

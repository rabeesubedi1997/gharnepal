import '../../../../../core/network/json_parsing.dart';
import '../../../../../core/network/media_url.dart';

/// Mirrors `AdvertisementResource` — targeted ad slots by `placement`
/// (see `AdPlacement`), NOT the same entity as `AdminBanner`.
class AdminAdvertisement {
  AdminAdvertisement({
    required this.id,
    this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkUrl,
    this.ctaLabel,
    required this.placement,
    required this.sortOrder,
    required this.isActive,
  });

  factory AdminAdvertisement.fromJson(Map<String, dynamic> json) {
    return AdminAdvertisement(
      id: asInt(json['id'])!,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      imageUrl: resolveMediaUrl(json['image_url'] as String),
      linkUrl: json['link_url'] as String?,
      ctaLabel: json['cta_label'] as String?,
      placement: json['placement'] as String,
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
  final String placement;
  final int sortOrder;
  final bool isActive;
}

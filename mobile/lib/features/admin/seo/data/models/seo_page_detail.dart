import '../../../../../core/network/media_url.dart';
import 'seo_competitor_scan.dart';

class SeoRobots {
  SeoRobots({required this.index, required this.follow});

  factory SeoRobots.fromJson(Map<String, dynamic> json) {
    return SeoRobots(index: json['index'] as bool? ?? true, follow: json['follow'] as bool? ?? true);
  }

  final bool index;
  final bool follow;
}

/// The live/effective meta for a page — either the admin override (if
/// present and published) or the auto-generated default. Never blank.
class SeoEffective {
  SeoEffective({
    required this.pageKey,
    required this.pageType,
    required this.label,
    required this.title,
    this.description,
    this.canonicalUrl,
    this.ogImage,
    required this.robots,
    this.structuredData,
    required this.hasOverride,
    this.overrideStatus,
  });

  factory SeoEffective.fromJson(Map<String, dynamic> json) {
    return SeoEffective(
      pageKey: json['page_key'] as String,
      pageType: json['page_type'] as String,
      label: json['label'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      canonicalUrl: json['canonical_url'] as String?,
      ogImage: json['og_image'] != null ? resolveMediaUrl(json['og_image'] as String) : null,
      robots: SeoRobots.fromJson(json['robots'] as Map<String, dynamic>? ?? const {}),
      structuredData: json['structured_data'],
      hasOverride: json['has_override'] as bool? ?? false,
      overrideStatus: json['override_status'] as String?,
    );
  }

  final String pageKey;
  final String pageType;
  final String label;
  final String title;
  final String? description;
  final String? canonicalUrl;
  final String? ogImage;
  final SeoRobots robots;
  final dynamic structuredData; // arbitrary JSON-LD, rendered raw
  final bool hasOverride;
  final String? overrideStatus; // draft | published | null
}

/// The admin-editable override row, if one exists.
class SeoOverride {
  SeoOverride({
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.ogImageUrl,
    this.canonicalPath,
    required this.robotsIndex,
    required this.robotsFollow,
    required this.status,
    required this.updatedAt,
  });

  factory SeoOverride.fromJson(Map<String, dynamic> json) {
    return SeoOverride(
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
      metaKeywords: json['meta_keywords'] as String?,
      ogImageUrl: json['og_image_url'] as String?,
      canonicalPath: json['canonical_path'] as String?,
      robotsIndex: json['robots_index'] as bool? ?? true,
      robotsFollow: json['robots_follow'] as bool? ?? true,
      status: json['status'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final String? ogImageUrl;
  final String? canonicalPath;
  final bool robotsIndex;
  final bool robotsFollow;
  final String status; // draft | published
  final String updatedAt;
}

/// `GET /admin/seo/pages/{key}` response: `{"data": {effective, override, scans}}`.
class SeoPageDetail {
  SeoPageDetail({required this.effective, this.override, required this.scans});

  factory SeoPageDetail.fromJson(Map<String, dynamic> json) {
    return SeoPageDetail(
      effective: SeoEffective.fromJson(json['effective'] as Map<String, dynamic>),
      override: json['override'] != null ? SeoOverride.fromJson(json['override'] as Map<String, dynamic>) : null,
      scans: (json['scans'] as List<dynamic>? ?? const [])
          .map((e) => SeoCompetitorScan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final SeoEffective effective;
  final SeoOverride? override;
  final List<SeoCompetitorScan> scans;
}

/// `PUT /admin/seo/pages/{key}` response: `{"data": {effective, override}}`
/// — no `scans` key, so this is a distinct (smaller) type from
/// [SeoPageDetail]. Callers should keep their existing scans list as-is.
class SeoPageEffectiveAndOverride {
  SeoPageEffectiveAndOverride({required this.effective, this.override});

  factory SeoPageEffectiveAndOverride.fromJson(Map<String, dynamic> json) {
    return SeoPageEffectiveAndOverride(
      effective: SeoEffective.fromJson(json['effective'] as Map<String, dynamic>),
      override: json['override'] != null ? SeoOverride.fromJson(json['override'] as Map<String, dynamic>) : null,
    );
  }

  final SeoEffective effective;
  final SeoOverride? override;
}

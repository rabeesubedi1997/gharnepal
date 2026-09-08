/// One row of `GET /admin/seo/pages` — plain JSON, not a Resource class.
class SeoPageSummary {
  SeoPageSummary({
    required this.pageKey,
    required this.pageType,
    required this.label,
    required this.path,
    required this.hasOverride,
    this.status,
    this.updatedAt,
  });

  factory SeoPageSummary.fromJson(Map<String, dynamic> json) {
    return SeoPageSummary(
      pageKey: json['page_key'] as String,
      pageType: json['page_type'] as String,
      label: json['label'] as String,
      path: json['path'] as String,
      hasOverride: json['has_override'] as bool? ?? false,
      status: json['status'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final String pageKey;
  final String pageType; // static | listing | neighborhood | agency | blog
  final String label;
  final String path;
  final bool hasOverride;
  final String? status; // draft | published | null
  final String? updatedAt;
}

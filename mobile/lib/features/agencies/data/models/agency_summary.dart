import '../../../../core/network/media_url.dart';

/// Mirrors `AgencyResource` — the public directory list item. The backend
/// only ever returns verified + active agencies here (hardcoded filter, no
/// client-passable params exist).
class AgencySummary {
  AgencySummary({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    required this.isVerified,
    required this.memberCount,
    required this.activeListingsCount,
  });

  factory AgencySummary.fromJson(Map<String, dynamic> json) {
    return AgencySummary(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] != null ? resolveMediaUrl(json['logo_url'] as String) : null,
      description: json['description'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      activeListingsCount: json['active_listings_count'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final bool isVerified;
  final int memberCount;
  final int activeListingsCount;
}

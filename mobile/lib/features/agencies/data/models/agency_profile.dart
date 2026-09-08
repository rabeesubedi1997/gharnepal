import '../../../../core/network/media_url.dart';
import '../../../listings/data/models/listing_summary.dart';

/// There's no separate "Agent" entity — an agent is just a `User` linked to
/// an `Agency` via a pivot carrying this role. Only `name` + role are ever
/// exposed publicly (no email/phone/photo).
class AgencyMember {
  AgencyMember({required this.name, required this.roleInAgency});

  factory AgencyMember.fromJson(Map<String, dynamic> json) {
    return AgencyMember(name: json['name'] as String, roleInAgency: json['role_in_agency'] as String);
  }

  final String name;
  final String roleInAgency; // owner_admin | agent

  bool get isAdmin => roleInAgency == 'owner_admin';
}

/// Mirrors `AgencyProfileResource`.
class AgencyProfile {
  AgencyProfile({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    required this.isVerified,
    this.verifiedAt,
    required this.memberCount,
    required this.members,
    required this.activeListings,
    required this.closedListingsCount,
    required this.closedListings,
  });

  factory AgencyProfile.fromJson(Map<String, dynamic> json) {
    return AgencyProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] != null ? resolveMediaUrl(json['logo_url'] as String) : null,
      description: json['description'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      members: (json['members'] as List<dynamic>? ?? const [])
          .map((m) => AgencyMember.fromJson(m as Map<String, dynamic>))
          .toList(growable: false),
      activeListings: (json['active_listings'] as List<dynamic>? ?? const [])
          .map((l) => ListingSummary.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
      closedListingsCount: json['closed_listings_count'] as int? ?? 0,
      closedListings: (json['closed_listings'] as List<dynamic>? ?? const [])
          .map((l) => ListingSummary.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final bool isVerified;
  final String? verifiedAt;
  final int memberCount;
  final List<AgencyMember> members;
  final List<ListingSummary> activeListings;
  final int closedListingsCount;
  final List<ListingSummary> closedListings;
}

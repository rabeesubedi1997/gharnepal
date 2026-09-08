import '../../../../../core/network/json_parsing.dart';

/// The abbreviated `listing`/`duplicate_of` objects nested on
/// `DuplicateListingFlagResource`. `price` is a decimal-backed field, so it
/// serializes as a JSON string.
class DuplicateFlagListingRef {
  DuplicateFlagListingRef({required this.id, required this.slug, required this.title, required this.price});

  factory DuplicateFlagListingRef.fromJson(Map<String, dynamic> json) {
    return DuplicateFlagListingRef(
      id: json['id'] as int,
      slug: json['slug'] as String,
      title: json['title'] as String,
      price: asDoubleOr(json['price'], 0),
    );
  }

  final int id;
  final String slug;
  final String title;
  final double price;
}

/// Mirrors `DuplicateListingFlagResource` — `GET /admin/duplicate-flags`,
/// `PATCH /admin/duplicate-flags/{id}/confirm`, `PATCH
/// /admin/duplicate-flags/{id}/dismiss`. `match_score` is a plain (safe)
/// number, not decimal-cast.
class AdminDuplicateFlag {
  AdminDuplicateFlag({
    required this.id,
    required this.listing,
    required this.duplicateOf,
    required this.matchScore,
    required this.matchReasons,
    required this.status,
    required this.createdAt,
  });

  factory AdminDuplicateFlag.fromJson(Map<String, dynamic> json) {
    return AdminDuplicateFlag(
      id: json['id'] as int,
      listing: DuplicateFlagListingRef.fromJson(json['listing'] as Map<String, dynamic>),
      duplicateOf: DuplicateFlagListingRef.fromJson(json['duplicate_of'] as Map<String, dynamic>),
      matchScore: asDoubleOr(json['match_score'], 0),
      matchReasons: (json['match_reasons'] as List<dynamic>? ?? const [])
          .map((r) => r.toString())
          .toList(growable: false),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final DuplicateFlagListingRef listing;
  final DuplicateFlagListingRef duplicateOf;
  final double matchScore;
  final List<String> matchReasons; // same_owner | similar_price | similar_area | similar_title | same_ward
  final String status; // unreviewed | confirmed | dismissed
  final String createdAt;
}

const kAdminDuplicateFlagStatuses = ['unreviewed', 'confirmed', 'dismissed'];

const kMatchReasonLabels = {
  'same_owner': 'Same owner',
  'similar_price': 'Similar price',
  'similar_area': 'Similar area',
  'similar_title': 'Similar title',
  'same_ward': 'Same ward',
};

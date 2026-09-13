import '../../../../../core/network/json_parsing.dart';

/// Mirrors `AmenityResource` — the shared reference list of amenities
/// attachable to a listing (search filter on the public side, checkbox list
/// on the post-property wizard). Previously seeder-only; this is the CRUD
/// screen for it (web has had one at `/admin/amenities` since it was closed
/// as an admin gap — this brings mobile to parity).
class AdminAmenity {
  AdminAmenity({
    required this.id,
    required this.key,
    required this.name,
    this.nameNe,
    this.category,
    this.icon,
  });

  factory AdminAmenity.fromJson(Map<String, dynamic> json) {
    return AdminAmenity(
      id: asInt(json['id'])!,
      key: json['key'] as String,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
    );
  }

  final int id;
  final String key;
  final String name;
  final String? nameNe;
  final String? category;
  final String? icon;
}

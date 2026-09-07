import '../../../core/network/media_url.dart';

/// Mirrors `MunicipalityResource` — used for the Home screen's
/// "browse by city" grid.
class Municipality {
  Municipality({
    required this.id,
    required this.districtId,
    required this.name,
    this.nameNe,
    required this.type,
    required this.code,
    required this.wardCount,
    this.imageUrl,
  });

  factory Municipality.fromJson(Map<String, dynamic> json) {
    return Municipality(
      id: json['id'] as int,
      districtId: json['district_id'] as int,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      type: json['type'] as String,
      code: json['code'] as String,
      wardCount: json['ward_count'] as int? ?? 0,
      imageUrl: json['image_url'] != null ? resolveMediaUrl(json['image_url'] as String) : null,
    );
  }

  final int id;
  final int districtId;
  final String name;
  final String? nameNe;
  final String type; // metropolitan | sub_metropolitan | municipality | rural_municipality
  final String code;
  final int wardCount;
  final String? imageUrl;
}

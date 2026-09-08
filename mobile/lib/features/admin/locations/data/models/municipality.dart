import '../../../../../core/network/media_url.dart';

/// The 4-value `type` enum `MunicipalityResource.type` accepts.
const kMunicipalityTypes = ['metropolitan', 'sub_metropolitan', 'municipality', 'rural_municipality'];

/// Mirrors `MunicipalityResource`.
class Municipality {
  Municipality({
    required this.id,
    required this.districtId,
    required this.name,
    required this.nameNe,
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
      wardCount: json['ward_count'] as int,
      imageUrl: json['image_url'] != null ? resolveMediaUrl(json['image_url'] as String) : null,
    );
  }

  final int id;
  final int districtId;
  final String name;
  final String? nameNe;
  final String type;
  final String code;
  final int wardCount;
  final String? imageUrl;
}

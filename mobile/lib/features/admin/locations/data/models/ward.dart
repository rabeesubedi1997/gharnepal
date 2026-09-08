import '../../../../../core/network/json_parsing.dart';

/// Mirrors `WardResource`. `centroid_lat`/`centroid_lng` serialize as JSON
/// strings (no Eloquent cast declared) — parsed via [asDouble].
class Ward {
  Ward({
    required this.id,
    required this.municipalityId,
    required this.wardNumber,
    this.name,
    this.centroidLat,
    this.centroidLng,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['id'] as int,
      municipalityId: json['municipality_id'] as int,
      wardNumber: json['ward_number'] as int,
      name: json['name'] as String?,
      centroidLat: asDouble(json['centroid_lat']),
      centroidLng: asDouble(json['centroid_lng']),
    );
  }

  final int id;
  final int municipalityId;
  final int wardNumber;
  final String? name;
  final double? centroidLat;
  final double? centroidLng;
}

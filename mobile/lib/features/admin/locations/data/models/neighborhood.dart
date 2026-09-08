import '../../../../../core/network/json_parsing.dart';

/// Mirrors `NeighborhoodResource`. `centroid_lat`/`centroid_lng` serialize as
/// JSON strings (no Eloquent cast declared) — parsed via [asDouble].
class Neighborhood {
  Neighborhood({
    required this.id,
    required this.wardId,
    required this.name,
    this.nameNe,
    this.centroidLat,
    this.centroidLng,
    required this.isCurated,
  });

  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      id: json['id'] as int,
      wardId: json['ward_id'] as int,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      centroidLat: asDouble(json['centroid_lat']),
      centroidLng: asDouble(json['centroid_lng']),
      isCurated: json['is_curated'] as bool? ?? false,
    );
  }

  final int id;
  final int wardId;
  final String name;
  final String? nameNe;
  final double? centroidLat;
  final double? centroidLng;
  final bool isCurated;
}

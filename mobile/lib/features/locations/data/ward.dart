import '../../../core/network/json_parsing.dart';

/// Mirrors `WardResource`.
class Ward {
  Ward({required this.id, required this.municipalityId, required this.wardNumber, this.name, this.lat, this.lng});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['id'] as int,
      municipalityId: json['municipality_id'] as int,
      wardNumber: json['ward_number'] as int,
      name: json['name'] as String?,
      lat: asDouble(json['centroid_lat']),
      lng: asDouble(json['centroid_lng']),
    );
  }

  final int id;
  final int municipalityId;
  final int wardNumber;
  final String? name;
  final double? lat;
  final double? lng;

  String get label => name ?? 'Ward $wardNumber';
}

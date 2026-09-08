import '../../../../core/network/json_parsing.dart';

/// The 6 points-of-interest categories, matching the DB enum, with labels
/// and icons for the profile page's POI list.
const kPoiTypes = {
  'school': 'School',
  'hospital': 'Hospital',
  'market': 'Market',
  'transport_stop': 'Transport stop',
  'bank': 'Bank',
  'other': 'Other',
};

/// Mirrors `NeighborhoodPoiResource`. `lat`/`lng` are uncast decimal columns
/// server-side — always JSON strings, never bare numbers.
class NeighborhoodPoi {
  NeighborhoodPoi({required this.id, required this.poiType, required this.name, this.lat, this.lng});

  factory NeighborhoodPoi.fromJson(Map<String, dynamic> json) {
    return NeighborhoodPoi(
      id: json['id'] as int,
      poiType: json['poi_type'] as String,
      name: json['name'] as String,
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
    );
  }

  final int id;
  final String poiType;
  final String name;
  final double? lat;
  final double? lng;

  String get typeLabel => kPoiTypes[poiType] ?? poiType;
}

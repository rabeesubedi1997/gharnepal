import '../../../../core/network/json_parsing.dart';

/// The `location` object on `PropertyListingSummaryResource` — a flattened
/// view distinct from the full nested `Address` on the detail resource.
class LocationSummary {
  LocationSummary({this.municipality, this.wardNumber, this.neighborhood, this.lat, this.lng});

  factory LocationSummary.fromJson(Map<String, dynamic> json) {
    return LocationSummary(
      municipality: json['municipality'] as String?,
      wardNumber: asInt(json['ward_number']),
      neighborhood: json['neighborhood'] as String?,
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
    );
  }

  final String? municipality;
  final int? wardNumber;
  final String? neighborhood;
  final double? lat;
  final double? lng;

  /// e.g. "Ward 5, Kathmandu" — a compact one-line summary for cards.
  String get summary {
    final parts = <String>[if (wardNumber != null) 'Ward $wardNumber', ?municipality];
    return parts.isEmpty ? '' : parts.join(', ');
  }
}

import '../../../../core/network/json_parsing.dart';

/// A small `{ id, name }` reference, used for province/district/municipality
/// on `AddressResource`.
class NamedRef {
  NamedRef({required this.id, required this.name});

  factory NamedRef.fromJson(Map<String, dynamic> json) {
    return NamedRef(id: json['id'] as int, name: (json['name'] ?? json['ward_number']).toString());
  }

  final int id;
  final String name;
}

/// Mirrors `AddressResource` on the listing detail's `property.address`.
class Address {
  Address({
    this.province,
    this.district,
    this.municipality,
    this.ward,
    this.neighborhood,
    this.streetAddress,
    this.landmark,
    this.lat,
    this.lng,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      province: _ref(json['province']),
      district: _ref(json['district']),
      municipality: _ref(json['municipality']),
      ward: _ref(json['ward']),
      neighborhood: _ref(json['neighborhood']),
      streetAddress: json['street_address'] as String?,
      landmark: json['landmark'] as String?,
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
    );
  }

  static NamedRef? _ref(dynamic value) {
    if (value == null) return null;
    return NamedRef.fromJson(value as Map<String, dynamic>);
  }

  final NamedRef? province;
  final NamedRef? district;
  final NamedRef? municipality;
  final NamedRef? ward;
  final NamedRef? neighborhood;
  final String? streetAddress;
  final String? landmark;
  final double? lat;
  final double? lng;

  bool get hasCoordinates => lat != null && lng != null;

  /// e.g. "Baneshwor, Kathmandu Metropolitan City, Ward 10".
  String get summary {
    final parts = <String>[
      if (neighborhood != null) neighborhood!.name,
      if (municipality != null) municipality!.name,
      if (ward != null) 'Ward ${ward!.name}',
    ];
    return parts.join(', ');
  }
}

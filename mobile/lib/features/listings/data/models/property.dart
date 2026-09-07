import '../../../../core/network/json_parsing.dart';
import 'address.dart';
import 'land_profile.dart';
import 'media_item.dart';

/// The `area` object on `PropertyResource` — canonical sqm plus the
/// originally-entered unit/value and a ready-made display table across all
/// Nepal land units (see AreaUnitConverter on both backend and mobile).
class AreaInfo {
  AreaInfo({this.sqm, this.enteredValue, this.enteredUnit, this.display});

  factory AreaInfo.fromJson(Map<String, dynamic> json) {
    return AreaInfo(
      sqm: asDouble(json['sqm']),
      enteredValue: asDouble(json['entered_value']),
      enteredUnit: json['entered_unit'] as String?,
      display: json['display'] != null
          ? (json['display'] as Map<String, dynamic>).map(
              (unit, value) => MapEntry(unit, asDoubleOr(value, 0)),
            )
          : null,
    );
  }

  final double? sqm;
  final double? enteredValue;
  final String? enteredUnit;
  final Map<String, double>? display;
}

/// Mirrors `PropertyResource` nested on the listing detail's `property` field.
class Property {
  Property({
    required this.id,
    required this.propertyType,
    required this.area,
    this.bedrooms,
    this.bathrooms,
    this.floors,
    this.yearBuilt,
    this.parkingSpaces,
    this.parkingType,
    this.isFurnished,
    this.address,
    required this.media,
    this.landProfile,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      propertyType: json['property_type'] as String,
      area: AreaInfo.fromJson(json['area'] as Map<String, dynamic>? ?? const {}),
      bedrooms: asInt(json['bedrooms']),
      bathrooms: asInt(json['bathrooms']),
      floors: asInt(json['floors']),
      yearBuilt: asInt(json['year_built']),
      parkingSpaces: asInt(json['parking_spaces']),
      parkingType: json['parking_type'] as String?,
      isFurnished: json['is_furnished'] as String?,
      address: json['address'] != null ? Address.fromJson(json['address'] as Map<String, dynamic>) : null,
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((m) => MediaItem.fromJson(m as Map<String, dynamic>))
          .toList(growable: false),
      landProfile: json['land_profile'] != null
          ? LandProfile.fromJson(json['land_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final String propertyType; // room | apartment | house | land | commercial
  final AreaInfo area;
  final int? bedrooms;
  final int? bathrooms;
  final int? floors;
  final int? yearBuilt;
  final int? parkingSpaces;
  final String? parkingType; // car | bike | both
  final String? isFurnished; // unfurnished | semi | full
  final Address? address;
  final List<MediaItem> media;
  final LandProfile? landProfile;

  List<MediaItem> get images => media.where((m) => m.type == 'image').toList(growable: false);
}

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

/// The abbreviated per-listing summary nested in `PropertyResource.listings`
/// — used on the Owner Dashboard's "My Properties" cards, one property can
/// (rarely) have more than one listing over its lifetime.
class OwnerListingSummary {
  OwnerListingSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.status,
    required this.purpose,
    required this.price,
    required this.isFeatured,
    this.featuredUntil,
  });

  factory OwnerListingSummary.fromJson(Map<String, dynamic> json) {
    return OwnerListingSummary(
      id: json['id'] as int,
      slug: json['slug'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      purpose: json['purpose'] as String,
      price: asDoubleOr(json['price'], 0),
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredUntil: json['featured_until'] as String?,
    );
  }

  final int id;
  final String slug;
  final String title;
  final String status;
  final String purpose;
  final double price;
  final bool isFeatured;
  final String? featuredUntil;
}

/// Mirrors `PropertyResource` nested on the listing detail's `property`
/// field, and also used standalone as an item of the Owner Dashboard's
/// "My Properties" list (`GET /owner/properties`), where `listings` is
/// populated instead of empty.
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
    this.listings = const [],
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
      listings: (json['listings'] as List<dynamic>? ?? const [])
          .map((l) => OwnerListingSummary.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
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
  final List<OwnerListingSummary> listings;

  List<MediaItem> get images => media.where((m) => m.type == 'image').toList(growable: false);
}

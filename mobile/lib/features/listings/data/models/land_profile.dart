import '../../../../core/network/json_parsing.dart';
import '../../../../core/network/media_url.dart';

/// Mirrors `LandProfileResource` — only present when `property_type == 'land'`.
/// See backend/app/Domain/Calculators/Services/AreaUnitConverter.php for the
/// unit conversions used to compute `Property.area.display` alongside this.
class LandProfile {
  LandProfile({
    required this.kittaNumber,
    required this.lalpurjaAvailable,
    required this.lalpurjaDocumentUrl,
    required this.roadAccess,
    required this.roadWidthMeters,
    required this.roadType,
    required this.waterAccess,
    required this.electricityAccess,
    required this.drainageAccess,
    required this.landClassification,
    required this.floodRisk,
    required this.landslideRisk,
    required this.nearbyDevelopmentNotes,
    required this.documentVerificationStatus,
    required this.verifiedAt,
    required this.completenessPercent,
  });

  factory LandProfile.fromJson(Map<String, dynamic> json) {
    return LandProfile(
      kittaNumber: json['kitta_number'] as String?,
      lalpurjaAvailable: json['lalpurja_available'] as String,
      lalpurjaDocumentUrl: json['lalpurja_document_url'] != null
          ? resolveMediaUrl(json['lalpurja_document_url'] as String)
          : null,
      roadAccess: json['road_access'] as bool? ?? false,
      roadWidthMeters: asDouble(json['road_width_meters']),
      roadType: json['road_type'] as String,
      waterAccess: json['water_access'] as String,
      electricityAccess: json['electricity_access'] as bool? ?? false,
      drainageAccess: json['drainage_access'] as String,
      landClassification: json['land_classification'] as String,
      floodRisk: json['flood_risk'] as String,
      landslideRisk: json['landslide_risk'] as String,
      nearbyDevelopmentNotes: json['nearby_development_notes'] as String?,
      documentVerificationStatus: json['document_verification_status'] as String,
      verifiedAt: json['verified_at'] as String?,
      completenessPercent: asDoubleOr(json['completeness_percent'], 0),
    );
  }

  final String? kittaNumber;
  final String lalpurjaAvailable; // yes | no | in_process | unknown
  final String? lalpurjaDocumentUrl;
  final bool roadAccess;
  final double? roadWidthMeters;
  final String roadType; // blacktop | gravel | dirt | none
  final String waterAccess; // municipal | well | none | unknown
  final bool electricityAccess;
  final String drainageAccess; // yes | no | unknown
  final String landClassification;
  final String floodRisk; // none | low | medium | high | unknown
  final String landslideRisk;
  final String? nearbyDevelopmentNotes;
  final String documentVerificationStatus; // unverified | partial | verified
  final String? verifiedAt;
  final double completenessPercent;
}

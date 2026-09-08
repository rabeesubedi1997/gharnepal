import '../../../../core/network/json_parsing.dart';

/// The 7 selectable lifestyle tags, exactly matching
/// `MatchPreference::LIFESTYLE_TAGS` server-side (`max:7` — i.e. every tag
/// may be picked at once).
const kLifestyleTags = {
  'quiet': 'Quiet',
  'safe': 'Safe',
  'family_friendly': 'Family-friendly',
  'well_connected': 'Well-connected',
  'low_flood_risk': 'Low flood risk',
  'good_internet': 'Good internet',
  'vibrant_markets': 'Vibrant markets',
};

/// Mirrors `MatchPreferenceResource`. `id == null` means the user hasn't
/// saved any preferences yet (the `GET` endpoint returns a transient unsaved
/// instance in that case, per the backend) — `hasSaved` is the exact gate
/// the website uses to decide whether to show results or a setup prompt.
class MatchPreference {
  MatchPreference({
    this.id,
    this.purpose,
    this.propertyType,
    this.budgetMin,
    this.budgetMax,
    this.minBedrooms,
    this.preferredMunicipalityId,
    this.preferredMunicipality,
    this.workLat,
    this.workLng,
    this.workLocationLabel,
    this.commuteLimitMinutes,
    this.familySize,
    this.requiresSchoolNearby,
    this.requiresParking,
    this.investmentPurpose,
    this.lifestyleTags = const [],
  });

  factory MatchPreference.fromJson(Map<String, dynamic> json) {
    return MatchPreference(
      id: json['id'] as int?,
      purpose: json['purpose'] as String?,
      propertyType: json['property_type'] as String?,
      budgetMin: asDouble(json['budget_min']),
      budgetMax: asDouble(json['budget_max']),
      minBedrooms: asInt(json['min_bedrooms']),
      preferredMunicipalityId: json['preferred_municipality_id'] as int?,
      preferredMunicipality: json['preferred_municipality'] as String?,
      workLat: asDouble(json['work_lat']),
      workLng: asDouble(json['work_lng']),
      workLocationLabel: json['work_location_label'] as String?,
      commuteLimitMinutes: asInt(json['commute_limit_minutes']),
      familySize: asInt(json['family_size']),
      requiresSchoolNearby: json['requires_school_nearby'] as bool?,
      requiresParking: json['requires_parking'] as bool?,
      investmentPurpose: json['investment_purpose'] as bool?,
      lifestyleTags: (json['lifestyle_tags'] as List<dynamic>? ?? const [])
          .map((t) => t.toString())
          .toList(growable: false),
    );
  }

  final int? id;
  final String? purpose; // sale | rent
  final String? propertyType;
  final double? budgetMin;
  final double? budgetMax;
  final int? minBedrooms;
  final int? preferredMunicipalityId;
  final String? preferredMunicipality;
  final double? workLat;
  final double? workLng;
  final String? workLocationLabel;
  final int? commuteLimitMinutes;
  final int? familySize;
  final bool? requiresSchoolNearby;
  final bool? requiresParking;
  final bool? investmentPurpose;
  final List<String> lifestyleTags;

  bool get hasSaved => id != null;
  bool get hasWorkLocation => workLat != null && workLng != null;
}

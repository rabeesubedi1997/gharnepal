import 'neighborhood_score.dart';

/// The `ward` object nested on `NeighborhoodSummaryResource` — a flattened
/// view distinct from the full `Ward` model used elsewhere (locations
/// feature), so kept local to this feature.
class NeighborhoodWardRef {
  NeighborhoodWardRef({required this.id, required this.wardNumber, required this.municipality});

  factory NeighborhoodWardRef.fromJson(Map<String, dynamic> json) {
    return NeighborhoodWardRef(
      id: json['id'] as int,
      wardNumber: json['ward_number'] as int,
      municipality: json['municipality'] as String,
    );
  }

  final int id;
  final int wardNumber;
  final String municipality;
}

/// Mirrors `NeighborhoodSummaryResource` — the directory list item.
class NeighborhoodSummary {
  NeighborhoodSummary({
    required this.id,
    required this.name,
    this.nameNe,
    required this.isCurated,
    required this.ward,
    this.score,
  });

  factory NeighborhoodSummary.fromJson(Map<String, dynamic> json) {
    return NeighborhoodSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      nameNe: json['name_ne'] as String?,
      isCurated: json['is_curated'] as bool? ?? false,
      ward: NeighborhoodWardRef.fromJson(json['ward'] as Map<String, dynamic>),
      score: json['score'] != null ? NeighborhoodScore.fromJson(json['score'] as Map<String, dynamic>) : null,
    );
  }

  final int id;
  final String name;
  final String? nameNe;
  final bool isCurated;
  final NeighborhoodWardRef ward;
  final NeighborhoodScore? score;

  /// e.g. "Baneshwor, Kathmandu Metropolitan City" — used both for display
  /// and as the client-side search haystack (the directory has no server
  /// search, per the backend contract).
  String get searchHaystack => '$name ${ward.municipality}'.toLowerCase();
}

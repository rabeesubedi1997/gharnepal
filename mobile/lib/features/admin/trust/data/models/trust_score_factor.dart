/// Mirrors `Admin\TrustScoreFactorResource` — one of the 9 fixed factor keys
/// that make up `ListingTrustScore.computed_score`. Factors can't be added
/// or removed here, only globally tuned (`max_points`/`is_active`); none of
/// this retroactively recomputes any listing's already-computed score.
class TrustScoreFactor {
  TrustScoreFactor({
    required this.id,
    required this.key,
    required this.label,
    required this.description,
    required this.maxPoints,
    required this.isActive,
  });

  factory TrustScoreFactor.fromJson(Map<String, dynamic> json) {
    return TrustScoreFactor(
      id: json['id'] as int,
      key: json['key'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      maxPoints: json['max_points'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  final int id;
  final String key;
  final String label;
  final String? description;
  final int maxPoints;
  final bool isActive;
}

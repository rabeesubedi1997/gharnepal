import '../../../../core/network/json_parsing.dart';

/// One row of `TrustScoreResource.breakdown` — a single explainable factor.
class TrustFactorBreakdown {
  TrustFactorBreakdown({
    required this.key,
    required this.label,
    required this.description,
    required this.pointsAwarded,
    required this.maxPoints,
    required this.explanation,
  });

  factory TrustFactorBreakdown.fromJson(Map<String, dynamic> json) {
    return TrustFactorBreakdown(
      key: json['key'] as String?,
      label: json['label'] as String?,
      description: json['description'] as String?,
      pointsAwarded: asDoubleOr(json['points_awarded'], 0),
      maxPoints: asDoubleOr(json['max_points'], 0),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  final String? key;
  final String? label;
  final String? description;
  final double pointsAwarded;
  final double maxPoints;
  final String explanation;
}

/// Mirrors `TrustScoreResource` — the "Trust Index" shown as a badge with an
/// expandable per-factor explanation, never a bare opaque number.
class TrustScore {
  TrustScore({
    required this.score,
    required this.computedScore,
    required this.isOverridden,
    required this.computedAt,
    required this.breakdown,
  });

  factory TrustScore.fromJson(Map<String, dynamic> json) {
    return TrustScore(
      score: json['score'] as int,
      computedScore: json['computed_score'] as int,
      isOverridden: json['is_overridden'] as bool? ?? false,
      computedAt: json['computed_at'] as String?,
      breakdown: (json['breakdown'] as List<dynamic>? ?? const [])
          .map((row) => TrustFactorBreakdown.fromJson(row as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int score;
  final int computedScore;
  final bool isOverridden;
  final String? computedAt;
  final List<TrustFactorBreakdown> breakdown;

  /// Mirrors the website's tiering: >=70 green "Trusted", >=40 amber
  /// "Fair trust", else red "Low trust".
  TrustTier get tier {
    if (score >= 70) return TrustTier.trusted;
    if (score >= 40) return TrustTier.fair;
    return TrustTier.low;
  }
}

enum TrustTier { trusted, fair, low }

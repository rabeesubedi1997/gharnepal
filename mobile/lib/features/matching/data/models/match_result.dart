import '../../../listings/data/models/listing_summary.dart';

/// One scored factor behind a match — `points`/`max_points` are shown as a
/// fraction next to `explanation` in the "Why this match?" panel.
class MatchReason {
  MatchReason({required this.label, required this.points, required this.maxPoints, required this.explanation});

  factory MatchReason.fromJson(Map<String, dynamic> json) {
    return MatchReason(
      label: json['label'] as String,
      points: json['points'] as int,
      maxPoints: json['max_points'] as int,
      explanation: json['explanation'] as String,
    );
  }

  final String label;
  final int points;
  final int maxPoints;
  final String explanation;
}

/// Mirrors `MatchResultResource`. `score` is 0-100; `reasons` come straight
/// from `MatchScorer` (see its explicit "(straight-line estimate)" wording
/// on commute-related reasons — this is haversine distance / an assumed
/// 20km/h, not real routing, so keep that phrasing verbatim if shown).
class MatchResult {
  MatchResult({required this.id, required this.score, required this.reasons, required this.computedAt, required this.listing});

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      id: json['id'] as int,
      score: json['score'] as int,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((r) => MatchReason.fromJson(r as Map<String, dynamic>))
          .toList(growable: false),
      computedAt: json['computed_at'] as String,
      listing: ListingSummary.fromJson(json['listing'] as Map<String, dynamic>),
    );
  }

  final int id;
  final int score;
  final List<MatchReason> reasons;
  final String computedAt;
  final ListingSummary listing;
}

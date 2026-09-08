/// The 11 scoreable factors, exactly matching `NeighborhoodScore::FACTORS`
/// server-side, with the labels the directory/profile pages show.
const kNeighborhoodScoreFactors = {
  'transport_access': 'Transport access',
  'schools': 'Schools',
  'hospitals': 'Hospitals',
  'markets': 'Markets',
  'internet_availability': 'Internet availability',
  'road_quality': 'Road quality',
  'noise': 'Noise',
  'safety': 'Safety',
  'flood_risk': 'Flood risk',
  'rental_demand': 'Rental demand',
  'development_activity': 'Development activity',
};

class NeighborhoodScoreFactor {
  NeighborhoodScoreFactor({required this.key, required this.score, this.notes});

  factory NeighborhoodScoreFactor.fromJson(Map<String, dynamic> json) {
    return NeighborhoodScoreFactor(
      key: json['key'] as String,
      score: json['score'] as int,
      notes: json['notes'] as String?,
    );
  }

  final String key;
  final int score; // 0-10
  final String? notes;

  String get label => kNeighborhoodScoreFactors[key] ?? key;
}

/// Mirrors the `score` object on `NeighborhoodSummaryResource`/
/// `NeighborhoodProfileResource`. `factors` is only ever populated on the
/// detail endpoint — the directory list always returns `[]` here since it
/// doesn't eager-load that nested relation.
class NeighborhoodScore {
  NeighborhoodScore({
    required this.overallScore,
    required this.source,
    this.computedAt,
    this.factors = const [],
  });

  factory NeighborhoodScore.fromJson(Map<String, dynamic> json) {
    return NeighborhoodScore(
      overallScore: json['overall_score'] as int,
      source: json['source'] as String,
      computedAt: json['computed_at'] as String?,
      factors: (json['factors'] as List<dynamic>? ?? const [])
          .map((f) => NeighborhoodScoreFactor.fromJson(f as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int overallScore; // 0-10
  final String source; // e.g. admin_curated
  final String? computedAt;
  final List<NeighborhoodScoreFactor> factors;
}

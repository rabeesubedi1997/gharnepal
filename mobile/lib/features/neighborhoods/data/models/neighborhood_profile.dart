import 'community_note.dart';
import 'neighborhood_poi.dart';
import 'neighborhood_score.dart';
import 'neighborhood_summary.dart';

/// Mirrors `NeighborhoodProfileResource` — the summary shape plus POIs and
/// approved community notes. There is no "nearby listings" section on this
/// resource at all (confirmed against the backend — not an omission here).
class NeighborhoodProfile {
  NeighborhoodProfile({
    required this.id,
    required this.name,
    this.nameNe,
    required this.isCurated,
    required this.ward,
    this.score,
    required this.pois,
    required this.communityNotes,
  });

  factory NeighborhoodProfile.fromJson(Map<String, dynamic> json) {
    final summary = NeighborhoodSummary.fromJson(json);
    return NeighborhoodProfile(
      id: summary.id,
      name: summary.name,
      nameNe: summary.nameNe,
      isCurated: summary.isCurated,
      ward: summary.ward,
      score: summary.score,
      pois: (json['pois'] as List<dynamic>? ?? const [])
          .map((p) => NeighborhoodPoi.fromJson(p as Map<String, dynamic>))
          .toList(growable: false),
      communityNotes: (json['community_notes'] as List<dynamic>? ?? const [])
          .map((n) => CommunityNote.fromJson(n as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final String? nameNe;
  final bool isCurated;
  final NeighborhoodWardRef ward;
  final NeighborhoodScore? score;
  final List<NeighborhoodPoi> pois;
  final List<CommunityNote> communityNotes;
}

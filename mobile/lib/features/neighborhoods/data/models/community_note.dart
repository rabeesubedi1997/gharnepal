/// The 9 note categories, matching the DB enum, with labels for the
/// submission form's dropdown.
const kCommunityNoteCategories = {
  'water_supply': 'Water supply',
  'power_interruption': 'Power interruption',
  'road_condition': 'Road condition',
  'isp_quality': 'ISP quality',
  'parking_difficulty': 'Parking difficulty',
  'seasonal_flooding': 'Seasonal flooding',
  'noise': 'Noise',
  'market_access': 'Market access',
  'other': 'Other',
};

/// Mirrors `CommunityNoteResource`. The public neighborhood-detail endpoint
/// only ever embeds `status: 'approved'` notes — a note the current user
/// just submitted themselves (`status: 'pending'`) is returned once from the
/// create call but won't show up in the neighborhood's list until approved.
class CommunityNote {
  CommunityNote({
    required this.id,
    required this.neighborhoodId,
    required this.category,
    required this.body,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory CommunityNote.fromJson(Map<String, dynamic> json) {
    return CommunityNote(
      id: json['id'] as int,
      neighborhoodId: json['neighborhood_id'] as int,
      category: json['category'] as String,
      body: json['body'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final int neighborhoodId;
  final String category;
  final String body;
  final String status; // pending | approved | rejected | flagged_removed
  final String? rejectionReason;
  final String createdAt;

  String get categoryLabel => kCommunityNoteCategories[category] ?? category;
}

/// The `user` relation on the consumer-facing `RatingResource` — null only
/// if the rater's account was deleted.
class RatingUserRef {
  RatingUserRef({required this.name});

  factory RatingUserRef.fromJson(Map<String, dynamic> json) {
    return RatingUserRef(name: json['name'] as String);
  }

  final String name;
}

/// Mirrors `RatingResource` (backend/app/Http/Resources/RatingResource.php)
/// — GET /listings/{listing}/ratings. Deliberately has no `status` field:
/// unlike `Admin\RatingResource`, this endpoint is pre-filtered to
/// `status == 'visible'`, so every row here is already safe to show.
class ListingRating {
  ListingRating({required this.id, required this.score, this.comment, this.user, required this.createdAt});

  factory ListingRating.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ListingRating(
      id: json['id'] as int,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      user: user != null ? RatingUserRef.fromJson(user) : null,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final int score; // 1-5
  final String? comment;
  final RatingUserRef? user;
  final String createdAt;
}

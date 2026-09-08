/// The `user` relation on `Admin\RatingResource` — null only if the rater's
/// account was deleted.
class RatingUserRef {
  RatingUserRef({required this.id, required this.name});

  factory RatingUserRef.fromJson(Map<String, dynamic> json) {
    return RatingUserRef(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// The `listing` relation on `Admin\RatingResource` — null if the underlying
/// listing was deleted.
class RatingListingRef {
  RatingListingRef({required this.id, required this.slug, required this.title});

  factory RatingListingRef.fromJson(Map<String, dynamic> json) {
    return RatingListingRef(
      id: json['id'] as int,
      slug: json['slug'] as String,
      title: json['title'] as String,
    );
  }

  final int id;
  final String slug;
  final String title;
}

/// Mirrors `Admin\RatingResource`. The `rateable` polymorphic relation is
/// only ever a `PropertyListing` today, surfaced here directly as [listing].
class Rating {
  Rating({
    required this.id,
    required this.score,
    this.comment,
    required this.status,
    this.user,
    this.listing,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final listing = json['listing'] as Map<String, dynamic>?;
    return Rating(
      id: json['id'] as int,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      status: json['status'] as String,
      user: user != null ? RatingUserRef.fromJson(user) : null,
      listing: listing != null ? RatingListingRef.fromJson(listing) : null,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final int score; // 1-5
  final String? comment;
  final String status; // visible | hidden
  final RatingUserRef? user;
  final RatingListingRef? listing;
  final String createdAt;
}

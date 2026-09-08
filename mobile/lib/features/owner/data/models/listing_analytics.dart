/// `GET /owner/listings/{listing}/analytics` — a raw `{data: {...}}` payload,
/// not a Resource class, all plain ints.
class ListingAnalytics {
  ListingAnalytics({
    required this.viewsCount,
    required this.favoritesCount,
    required this.inquiriesCount,
    required this.viewingRequestsCount,
  });

  factory ListingAnalytics.fromJson(Map<String, dynamic> json) {
    return ListingAnalytics(
      viewsCount: json['views_count'] as int? ?? 0,
      favoritesCount: json['favorites_count'] as int? ?? 0,
      inquiriesCount: json['inquiries_count'] as int? ?? 0,
      viewingRequestsCount: json['viewing_requests_count'] as int? ?? 0,
    );
  }

  final int viewsCount;
  final int favoritesCount;
  final int inquiriesCount;
  final int viewingRequestsCount;
}

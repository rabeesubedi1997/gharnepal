/// One row of `GET /agency/dashboard/site-visits` — upcoming (next 7 days)
/// viewing requests across the agency's own listings.
class AgencySiteVisit {
  AgencySiteVisit({
    required this.id,
    this.when,
    required this.isConfirmed,
    this.listingTitle,
    this.listingSlug,
    this.municipality,
    this.requesterName,
  });

  factory AgencySiteVisit.fromJson(Map<String, dynamic> json) {
    return AgencySiteVisit(
      id: json['id'] as int,
      when: json['when'] as String?,
      isConfirmed: json['is_confirmed'] as bool? ?? false,
      listingTitle: json['listing_title'] as String?,
      listingSlug: json['listing_slug'] as String?,
      municipality: json['municipality'] as String?,
      requesterName: json['requester_name'] as String?,
    );
  }

  final int id;
  final String? when; // ISO8601, or null if genuinely unscheduled
  final bool isConfirmed;
  final String? listingTitle;
  final String? listingSlug;
  final String? municipality;
  final String? requesterName;
}

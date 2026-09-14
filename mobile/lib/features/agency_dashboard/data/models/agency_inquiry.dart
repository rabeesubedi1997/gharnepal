/// One row of `GET /agency/dashboard/inquiries` — the agency-wide buyer
/// inquiries feed (member's own conversations, not just the current user's).
class AgencyInquiry {
  AgencyInquiry({
    required this.id,
    this.buyerName,
    this.listingTitle,
    this.listingSlug,
    this.lastMessageAt,
    required this.messageCount,
  });

  factory AgencyInquiry.fromJson(Map<String, dynamic> json) {
    return AgencyInquiry(
      id: json['id'] as int,
      buyerName: json['buyer_name'] as String?,
      listingTitle: json['listing_title'] as String?,
      listingSlug: json['listing_slug'] as String?,
      lastMessageAt: json['last_message_at'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }

  final int id;
  final String? buyerName;
  final String? listingTitle;
  final String? listingSlug;
  final String? lastMessageAt;
  final int messageCount;
}

import '../../../listings/data/models/listing_summary.dart';

/// Mirrors the `filters_applied` object AssistantService::describeFilters()
/// returns — what the rule-based parser understood from the message, shown
/// as chips so the user can see (and correct) a misparse.
class AssistantFiltersApplied {
  AssistantFiltersApplied({
    required this.purpose,
    required this.propertyType,
    required this.location,
    required this.priceLabel,
    required this.bedroomsMin,
    required this.amenities,
  });

  factory AssistantFiltersApplied.fromJson(Map<String, dynamic> json) {
    return AssistantFiltersApplied(
      purpose: json['purpose'] as String?,
      propertyType: json['property_type'] as String?,
      location: json['location'] as String?,
      priceLabel: json['price_label'] as String?,
      bedroomsMin: json['bedrooms_min'] as int?,
      amenities: (json['amenities'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }

  final String? purpose;
  final String? propertyType;
  final String? location;
  final String? priceLabel;
  final int? bedroomsMin;
  final List<String> amenities;

  /// Short display chips, in a sensible reading order — empty when nothing
  /// meaningful was resolved (e.g. a clarifying-question reply).
  List<String> get chips => [
    if (purpose == 'rent') 'For rent' else if (purpose == 'sale') 'For sale',
    if (propertyType != null) propertyType![0].toUpperCase() + propertyType!.substring(1),
    ?location,
    ?priceLabel,
    if (bedroomsMin != null) '$bedroomsMin+ bedrooms',
  ];
}

/// Mirrors AssistantController::chat()'s JSON response.
class AssistantChatResponse {
  AssistantChatResponse({
    required this.conversationId,
    required this.guestToken,
    required this.reply,
    required this.listings,
    required this.filtersApplied,
  });

  factory AssistantChatResponse.fromJson(Map<String, dynamic> json) {
    return AssistantChatResponse(
      conversationId: json['conversation_id'] as int,
      guestToken: json['guest_token'] as String,
      reply: json['reply'] as String,
      listings: (json['listings'] as List<dynamic>? ?? const [])
          .map((l) => ListingSummary.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
      filtersApplied: AssistantFiltersApplied.fromJson(json['filters_applied'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final int conversationId;
  final String guestToken;
  final String reply;
  final List<ListingSummary> listings;
  final AssistantFiltersApplied filtersApplied;
}

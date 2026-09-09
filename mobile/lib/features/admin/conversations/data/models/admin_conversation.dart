import '../../../../../core/network/json_parsing.dart';
import 'admin_message.dart';

class AdminConversationListingRef {
  AdminConversationListingRef({required this.id, required this.slug, required this.title});

  factory AdminConversationListingRef.fromJson(Map<String, dynamic> json) {
    return AdminConversationListingRef(
      id: asInt(json['id'])!,
      slug: json['slug'] as String,
      title: json['title'] as String,
    );
  }

  final int id;
  final String slug;
  final String title;
}

class AdminConversationPropertyRequestRef {
  AdminConversationPropertyRequestRef({required this.id, required this.purpose, this.propertyType});

  factory AdminConversationPropertyRequestRef.fromJson(Map<String, dynamic> json) {
    return AdminConversationPropertyRequestRef(
      id: asInt(json['id'])!,
      purpose: json['purpose'] as String,
      propertyType: json['property_type'] as String?,
    );
  }

  final int id;
  final String purpose;
  final String? propertyType;
}

class AdminConversationParticipant {
  AdminConversationParticipant({required this.id, required this.name, this.email});

  factory AdminConversationParticipant.fromJson(Map<String, dynamic> json) {
    return AdminConversationParticipant(
      id: asInt(json['id'])!,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }

  final int id;
  final String name;
  final String? email;
}

/// Mirrors `Admin\ConversationResource`. `messages` is only a 1-item preview
/// on the list endpoint, and the full thread on the show endpoint.
class AdminConversation {
  AdminConversation({
    required this.id,
    required this.status,
    this.listing,
    this.propertyRequest,
    this.buyer,
    this.owner,
    this.messagesCount,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.messages,
  });

  factory AdminConversation.fromJson(Map<String, dynamic> json) {
    return AdminConversation(
      id: asInt(json['id'])!,
      status: json['status'] as String,
      listing: json['listing'] != null
          ? AdminConversationListingRef.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
      propertyRequest: json['property_request'] != null
          ? AdminConversationPropertyRequestRef.fromJson(json['property_request'] as Map<String, dynamic>)
          : null,
      buyer: json['buyer'] != null
          ? AdminConversationParticipant.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      owner: json['owner'] != null
          ? AdminConversationParticipant.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      messagesCount: asInt(json['messages_count']),
      lastMessageAt: json['last_message_at'] as String?,
      lastMessagePreview: json['last_message_preview'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((m) => AdminMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String status; // open | closed
  final AdminConversationListingRef? listing;
  final AdminConversationPropertyRequestRef? propertyRequest;
  final AdminConversationParticipant? buyer;
  final AdminConversationParticipant? owner;
  final int? messagesCount;
  final String? lastMessageAt;
  final String? lastMessagePreview;
  final List<AdminMessage> messages;

  /// There is no backend field marking a message as "from support" — this
  /// replicates the website's exact client-side inference: a message is a
  /// "support" message if its sender is neither the buyer nor the owner.
  bool isSupportMessage(AdminMessage message) {
    final senderId = message.sender?.id;
    return senderId != buyer?.id && senderId != owner?.id;
  }

  /// A short subtitle: the listing title, or a generic property-request
  /// label when this thread came from the demand-side board instead.
  String get subject {
    if (listing != null) return listing!.title;
    if (propertyRequest != null) return 'Property request (${propertyRequest!.purpose})';
    return 'Conversation';
  }
}

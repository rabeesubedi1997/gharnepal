import '../../../../core/network/json_parsing.dart';
import '../../../../core/network/media_url.dart';
import 'message.dart';

class ConversationListingRef {
  ConversationListingRef({required this.id, required this.slug, required this.title, this.coverImageUrl});

  factory ConversationListingRef.fromJson(Map<String, dynamic> json) {
    return ConversationListingRef(
      id: asInt(json['id'])!,
      slug: json['slug'] as String,
      title: json['title'] as String,
      coverImageUrl: json['cover_image_url'] != null
          ? resolveMediaUrl(json['cover_image_url'] as String)
          : null,
    );
  }

  final int id;
  final String slug;
  final String title;
  final String? coverImageUrl;
}

class ConversationPropertyRequestRef {
  ConversationPropertyRequestRef({required this.id, required this.purpose, this.propertyType});

  factory ConversationPropertyRequestRef.fromJson(Map<String, dynamic> json) {
    return ConversationPropertyRequestRef(
      id: asInt(json['id'])!,
      purpose: json['purpose'] as String,
      propertyType: json['property_type'] as String?,
    );
  }

  final int id;
  final String purpose;
  final String? propertyType;
}

class ConversationParticipant {
  ConversationParticipant({required this.id, required this.name});

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(id: asInt(json['id'])!, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Mirrors `ConversationResource`. `messages` is only populated on the
/// `show` endpoint (the list endpoint always sends `[]`).
class Conversation {
  Conversation({
    this.listing,
    this.propertyRequest,
    this.otherParticipant,
    required this.id,
    required this.status,
    this.lastMessageAt,
    required this.unreadCount,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: asInt(json['id'])!,
      listing: json['listing'] != null
          ? ConversationListingRef.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
      propertyRequest: json['property_request'] != null
          ? ConversationPropertyRequestRef.fromJson(json['property_request'] as Map<String, dynamic>)
          : null,
      otherParticipant: json['other_participant'] != null
          ? ConversationParticipant.fromJson(json['other_participant'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String,
      lastMessageAt: json['last_message_at'] as String?,
      unreadCount: asInt(json['unread_count']) ?? 0,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final ConversationListingRef? listing;
  final ConversationPropertyRequestRef? propertyRequest;
  final ConversationParticipant? otherParticipant;
  final String status; // open | archived (nothing currently produces 'archived')
  final String? lastMessageAt;
  final int unreadCount;
  final List<Message> messages;

  /// A short subtitle for the conversation list: the listing title, or a
  /// generic "property request" label when this thread came from the
  /// demand-side board instead.
  String get subject {
    if (listing != null) return listing!.title;
    if (propertyRequest != null) return 'Property request (${propertyRequest!.purpose})';
    return 'Conversation';
  }
}

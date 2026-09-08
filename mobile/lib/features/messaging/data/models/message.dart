import '../../../../core/network/json_parsing.dart';

/// Mirrors `MessageResource`.
class Message {
  Message({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.senderId,
    required this.isMine,
    required this.isFromSupport,
    required this.readAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: asInt(json['id'])!,
      conversationId: asInt(json['conversation_id'])!,
      body: json['body'] as String,
      senderId: asInt(json['sender_id'])!,
      isMine: json['is_mine'] as bool? ?? false,
      isFromSupport: json['is_from_support'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final int conversationId;
  final String body;
  final int senderId;
  final bool isMine;
  final bool isFromSupport;
  final String? readAt;
  final String createdAt;
}

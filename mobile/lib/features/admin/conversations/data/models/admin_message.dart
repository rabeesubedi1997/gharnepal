import '../../../../../core/network/json_parsing.dart';

class AdminMessageSender {
  AdminMessageSender({required this.id, required this.name});

  factory AdminMessageSender.fromJson(Map<String, dynamic> json) {
    return AdminMessageSender(id: asInt(json['id'])!, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Mirrors `Admin\MessageResource`. There is no server-side field marking a
/// message as "from support" — callers must infer it from
/// `AdminConversation.isSupportMessage`.
class AdminMessage {
  AdminMessage({required this.id, required this.body, this.sender, this.readAt, required this.createdAt});

  factory AdminMessage.fromJson(Map<String, dynamic> json) {
    return AdminMessage(
      id: asInt(json['id'])!,
      body: json['body'] as String,
      sender: json['sender'] != null ? AdminMessageSender.fromJson(json['sender'] as Map<String, dynamic>) : null,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String body;
  final AdminMessageSender? sender;
  final String? readAt;
  final String createdAt;
}

/// Mirrors the raw `{id, type, data, read_at, created_at}` shape returned by
/// `NotificationController::index` — `data`'s inner fields vary by `type`
/// (new_message | listing_approved | listing_rejected | listing_featured),
/// so it's kept as an opaque map and read defensively; every type at least
/// has `data['message']`, a ready-to-display string. The presentation layer
/// switches on `type` to pick an icon.
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final String id;
  final String? type;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;

  bool get isUnread => readAt == null;
  String get message => data['message'] as String? ?? 'New notification';
}

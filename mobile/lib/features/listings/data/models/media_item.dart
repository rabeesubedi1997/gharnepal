import '../../../../core/network/media_url.dart';

/// Mirrors `MediaResource` — app/Http/Resources/MediaResource.php.
class MediaItem {
  MediaItem({required this.id, required this.type, required this.url, required this.sortOrder});

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as int,
      type: json['type'] as String,
      url: resolveMediaUrl(json['url'] as String),
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  final int id;
  final String type; // image | video | floor_plan | document
  final String url;
  final int sortOrder;
}

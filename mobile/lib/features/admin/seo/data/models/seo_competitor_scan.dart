import '../../../../../core/network/json_parsing.dart';
import '../../../../../core/network/media_url.dart';

class SeoScannedKeyword {
  SeoScannedKeyword({required this.word, required this.count});

  factory SeoScannedKeyword.fromJson(Map<String, dynamic> json) {
    return SeoScannedKeyword(word: json['word'] as String, count: asInt(json['count']) ?? 0);
  }

  final String word;
  final int count;
}

/// Mirrors `SeoCompetitorScanResource`. Only `status == 'pending'` scans are
/// ever returned by the API (latest-first).
class SeoCompetitorScan {
  SeoCompetitorScan({
    required this.id,
    required this.pageKey,
    required this.competitorUrl,
    this.scannedTitle,
    this.scannedMetaDescription,
    this.scannedMetaKeywords,
    required this.scannedHeadings,
    required this.scannedKeywords,
    this.scannedOgImage,
    required this.wordCount,
    this.scannedBy,
    required this.createdAt,
  });

  factory SeoCompetitorScan.fromJson(Map<String, dynamic> json) {
    return SeoCompetitorScan(
      id: asInt(json['id'])!,
      pageKey: json['page_key'] as String,
      competitorUrl: json['competitor_url'] as String,
      scannedTitle: json['scanned_title'] as String?,
      scannedMetaDescription: json['scanned_meta_description'] as String?,
      scannedMetaKeywords: json['scanned_meta_keywords'] as String?,
      scannedHeadings: (json['scanned_headings'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      scannedKeywords: (json['scanned_keywords'] as List<dynamic>? ?? const [])
          .map((e) => SeoScannedKeyword.fromJson(e as Map<String, dynamic>))
          .toList(),
      scannedOgImage: json['scanned_og_image'] != null ? resolveMediaUrl(json['scanned_og_image'] as String) : null,
      wordCount: asInt(json['word_count']) ?? 0,
      scannedBy: json['scanned_by'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String pageKey;
  final String competitorUrl;
  final String? scannedTitle;
  final String? scannedMetaDescription;
  final String? scannedMetaKeywords;
  final List<String> scannedHeadings;
  final List<SeoScannedKeyword> scannedKeywords;
  final String? scannedOgImage;
  final int wordCount;
  final String? scannedBy;
  final String createdAt;

  /// Comma-joined words, for the "Use as keywords" quick-fill action.
  String get keywordsAsCsv => scannedKeywords.map((k) => k.word).join(', ');
}

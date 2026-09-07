import '../../../../core/network/json_parsing.dart';
import '../../../../core/network/media_url.dart';
import 'location_summary.dart';
import 'rating_summary.dart';

/// Mirrors `PropertyListingSummaryResource` — the shape returned both by
/// `GET /listings` (search results) and nested as `similar_listings` on the
/// detail resource. Used to render `PropertyCard`.
class ListingSummary {
  ListingSummary({
    required this.id,
    required this.slug,
    required this.referenceCode,
    required this.title,
    required this.purpose,
    required this.price,
    required this.pricePeriod,
    required this.currency,
    required this.negotiable,
    required this.status,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.coverImageUrl,
    required this.location,
    required this.publishedAt,
    required this.viewsCount,
    required this.trustScore,
    required this.isFeatured,
    required this.rating,
  });

  factory ListingSummary.fromJson(Map<String, dynamic> json) {
    return ListingSummary(
      id: json['id'] as int,
      slug: json['slug'] as String,
      referenceCode: json['reference_code'] as String,
      title: json['title'] as String,
      purpose: json['purpose'] as String,
      price: asDoubleOr(json['price'], 0),
      pricePeriod: json['price_period'] as String?,
      currency: json['currency'] as String? ?? 'NPR',
      negotiable: json['negotiable'] as bool? ?? false,
      status: json['status'] as String,
      propertyType: json['property_type'] as String?,
      bedrooms: asInt(json['bedrooms']),
      bathrooms: asInt(json['bathrooms']),
      areaSqm: asDouble(json['area_sqm']),
      coverImageUrl: json['cover_image_url'] != null
          ? resolveMediaUrl(json['cover_image_url'] as String)
          : null,
      location: json['location'] != null
          ? LocationSummary.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      publishedAt: json['published_at'] as String?,
      viewsCount: asInt(json['views_count']) ?? 0,
      trustScore: asInt(json['trust_score']),
      isFeatured: json['is_featured'] as bool? ?? false,
      rating: RatingSummary.fromJson(json['rating'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final int id;
  final String slug;
  final String referenceCode;
  final String title;
  final String purpose; // sale | rent
  final double price;
  final String? pricePeriod; // total | monthly
  final String currency;
  final bool negotiable;
  final String status;
  final String? propertyType; // room | apartment | house | land | commercial
  final int? bedrooms;
  final int? bathrooms;
  final double? areaSqm;
  final String? coverImageUrl;
  final LocationSummary? location;
  final String? publishedAt;
  final int viewsCount;
  final int? trustScore;
  final bool isFeatured;
  final RatingSummary rating;

  bool get isClosed => status == 'rented' || status == 'sold';

  /// e.g. "/ month" suffix shown after the price for rentals.
  String get priceSuffix => pricePeriod == 'monthly' ? '/mo' : '';
}

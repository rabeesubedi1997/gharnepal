import '../../../../core/network/json_parsing.dart';
import 'amenity.dart';
import 'listing_summary.dart';
import 'poster.dart';
import 'property.dart';
import 'rating_summary.dart';
import 'trust_score.dart';

class PriceHistoryEntry {
  PriceHistoryEntry({required this.price, required this.changedAt});

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      price: asDoubleOr(json['price'], 0),
      changedAt: json['changed_at'] as String,
    );
  }

  final double price;
  final String changedAt;
}

class MyRating {
  MyRating({required this.id, required this.score, this.comment});

  factory MyRating.fromJson(Map<String, dynamic> json) {
    return MyRating(
      id: json['id'] as int,
      score: json['score'] as int,
      comment: json['comment'] as String?,
    );
  }

  final int id;
  final int score;
  final String? comment;
}

/// Mirrors `PropertyListingDetailResource` — GET /listings/{slug}.
class ListingDetail {
  ListingDetail({
    required this.id,
    required this.slug,
    required this.referenceCode,
    required this.title,
    this.description,
    required this.purpose,
    required this.price,
    this.pricePeriod,
    required this.currency,
    required this.negotiable,
    this.availabilityDate,
    required this.status,
    this.publishedAt,
    required this.viewsCount,
    required this.isFeatured,
    this.featuredUntil,
    required this.property,
    required this.amenities,
    this.poster,
    this.trust,
    required this.priceHistory,
    required this.similarListings,
    required this.rating,
    this.myRating,
  });

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    return ListingDetail(
      id: json['id'] as int,
      slug: json['slug'] as String,
      referenceCode: json['reference_code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      purpose: json['purpose'] as String,
      price: asDoubleOr(json['price'], 0),
      pricePeriod: json['price_period'] as String?,
      currency: json['currency'] as String? ?? 'NPR',
      negotiable: json['negotiable'] as bool? ?? false,
      availabilityDate: json['availability_date'] as String?,
      status: json['status'] as String,
      publishedAt: json['published_at'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredUntil: json['featured_until'] as String?,
      property: Property.fromJson(json['property'] as Map<String, dynamic>),
      amenities: (json['amenities'] as List<dynamic>? ?? const [])
          .map((a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(growable: false),
      poster: json['poster'] != null ? Poster.fromJson(json['poster'] as Map<String, dynamic>) : null,
      trust: json['trust'] != null ? TrustScore.fromJson(json['trust'] as Map<String, dynamic>) : null,
      priceHistory: (json['price_history'] as List<dynamic>? ?? const [])
          .map((h) => PriceHistoryEntry.fromJson(h as Map<String, dynamic>))
          .toList(growable: false),
      similarListings: (json['similar_listings'] as List<dynamic>? ?? const [])
          .map((s) => ListingSummary.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
      rating: RatingSummary.fromJson(json['rating'] as Map<String, dynamic>? ?? const {}),
      myRating: json['my_rating'] != null ? MyRating.fromJson(json['my_rating'] as Map<String, dynamic>) : null,
    );
  }

  final int id;
  final String slug;
  final String referenceCode;
  final String title;
  final String? description;
  final String purpose;
  final double price;
  final String? pricePeriod;
  final String currency;
  final bool negotiable;
  final String? availabilityDate;
  final String status;
  final String? publishedAt;
  final int viewsCount;
  final bool isFeatured;
  final String? featuredUntil;
  final Property property;
  final List<Amenity> amenities;
  final Poster? poster;
  final TrustScore? trust;
  final List<PriceHistoryEntry> priceHistory;
  final List<ListingSummary> similarListings;
  final RatingSummary rating;
  final MyRating? myRating;

  bool get isClosed => status == 'rented' || status == 'sold';
  String get priceSuffix => pricePeriod == 'monthly' ? '/mo' : '';
}

import '../../../../core/network/json_parsing.dart';
import '../../../../core/network/media_url.dart';

class AgencyListingLocation {
  AgencyListingLocation({this.municipality, this.wardNumber});

  factory AgencyListingLocation.fromJson(Map<String, dynamic> json) {
    return AgencyListingLocation(
      municipality: json['municipality'] as String?,
      // Backend sends this as a bare JSON int (`ward_number` is an
      // unsigned-int column, no string cast) — a hard `as String?` here
      // throws and was silently taking down the whole Listings tab.
      wardNumber: json['ward_number']?.toString(),
    );
  }

  final String? municipality;
  final String? wardNumber;
}

/// Mirrors `AgencyListingRowResource` — one row of the agency dashboard's
/// Listings tab, `GET /agency/dashboard/listings` (paginated).
class AgencyDashboardListing {
  AgencyDashboardListing({
    required this.id,
    required this.slug,
    required this.referenceCode,
    required this.title,
    required this.purpose,
    required this.price,
    this.pricePeriod,
    required this.currency,
    this.propertyType,
    this.areaSqm,
    this.coverImageUrl,
    this.location,
    this.publishedAt,
    required this.inquiriesCount,
    required this.leadsCount,
  });

  factory AgencyDashboardListing.fromJson(Map<String, dynamic> json) {
    return AgencyDashboardListing(
      id: json['id'] as int,
      slug: json['slug'] as String,
      referenceCode: json['reference_code'] as String,
      title: json['title'] as String,
      purpose: json['purpose'] as String,
      price: asDoubleOr(json['price'], 0),
      pricePeriod: json['price_period'] as String?,
      currency: json['currency'] as String? ?? 'NPR',
      propertyType: json['property_type'] as String?,
      areaSqm: asDouble(json['area_sqm']),
      coverImageUrl: json['cover_image_url'] != null ? resolveMediaUrl(json['cover_image_url'] as String) : null,
      location: json['location'] != null
          ? AgencyListingLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      publishedAt: json['published_at'] as String?,
      inquiriesCount: json['inquiries_count'] as int? ?? 0,
      leadsCount: json['leads_count'] as int? ?? 0,
    );
  }

  final int id;
  final String slug;
  final String referenceCode;
  final String title;
  final String purpose;
  final double price;
  final String? pricePeriod;
  final String currency;
  final String? propertyType;
  final double? areaSqm;
  final String? coverImageUrl;
  final AgencyListingLocation? location;
  final String? publishedAt;
  final int inquiriesCount;
  final int leadsCount;

  String get priceSuffix => pricePeriod == 'monthly' ? '/mo' : '';
}

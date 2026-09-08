import '../../../../core/network/json_parsing.dart';
import '../../../listings/data/models/search_filters.dart';

/// Mirrors `SavedSearchResource`. `filters` round-trips whatever shape was
/// sent at creation verbatim (the backend only validates it as an array) —
/// this app always sends the same `SearchFilters.toQueryParams()` shape
/// used by GET /listings, so it can parse straight back into one.
class SavedSearch {
  SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
    required this.alertFrequency,
    this.lastNotifiedAt,
    required this.createdAt,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    final rawFilters = json['filters'] as Map<String, dynamic>? ?? const {};
    return SavedSearch(
      id: asInt(json['id'])!,
      name: json['name'] as String,
      filters: SearchFilters(
        purpose: rawFilters['purpose'] as String?,
        propertyType: rawFilters['property_type'] as String?,
        minPrice: asDouble(rawFilters['min_price']),
        maxPrice: asDouble(rawFilters['max_price']),
        bedroomsMin: asInt(rawFilters['bedrooms_min']),
        municipalityId: asInt(rawFilters['municipality_id']),
        q: rawFilters['q'] as String?,
        sort: rawFilters['sort'] as String? ?? 'newest',
        lalpurjaAvailable: rawFilters['lalpurja_available'] as String?,
        roadAccess: rawFilters['road_access'] as bool?,
      ),
      alertFrequency: json['alert_frequency'] as String? ?? 'instant',
      lastNotifiedAt: json['last_notified_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String name;
  final SearchFilters filters;
  final String alertFrequency; // instant | daily | weekly | off
  final String? lastNotifiedAt;
  final String createdAt;
}

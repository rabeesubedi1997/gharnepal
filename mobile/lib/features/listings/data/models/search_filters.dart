/// Mirrors `SearchFilters` in frontend/src/lib/api/listings.ts — the exact
/// query params `Public\ListingController::index` accepts. Immutable; the
/// search screen holds one of these in a Riverpod provider and calls
/// `copyWith` on every filter change.
class SearchFilters {
  const SearchFilters({
    this.purpose,
    this.propertyType,
    this.minPrice,
    this.maxPrice,
    this.bedroomsMin,
    this.municipalityId,
    this.q,
    this.sort = 'newest',
    this.lalpurjaAvailable,
    this.roadAccess,
  });

  final String? purpose; // sale | rent
  final String? propertyType; // room | apartment | house | land | commercial
  final double? minPrice;
  final double? maxPrice;
  final int? bedroomsMin;
  final int? municipalityId;
  final String? q;
  final String sort; // newest | price_asc | price_desc
  final String? lalpurjaAvailable; // yes | no | in_process | unknown
  final bool? roadAccess;

  bool get isLand => propertyType == 'land';

  SearchFilters copyWith({
    String? purpose,
    bool clearPurpose = false,
    String? propertyType,
    bool clearPropertyType = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    int? bedroomsMin,
    bool clearBedroomsMin = false,
    int? municipalityId,
    bool clearMunicipalityId = false,
    String? q,
    String? sort,
    String? lalpurjaAvailable,
    bool clearLalpurjaAvailable = false,
    bool? roadAccess,
    bool clearRoadAccess = false,
  }) {
    return SearchFilters(
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
      propertyType: clearPropertyType ? null : (propertyType ?? this.propertyType),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      bedroomsMin: clearBedroomsMin ? null : (bedroomsMin ?? this.bedroomsMin),
      municipalityId: clearMunicipalityId ? null : (municipalityId ?? this.municipalityId),
      q: q ?? this.q,
      sort: sort ?? this.sort,
      lalpurjaAvailable: clearLalpurjaAvailable ? null : (lalpurjaAvailable ?? this.lalpurjaAvailable),
      roadAccess: clearRoadAccess ? null : (roadAccess ?? this.roadAccess),
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (purpose != null) 'purpose': purpose,
      if (propertyType != null) 'property_type': propertyType,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (bedroomsMin != null) 'bedrooms_min': bedroomsMin,
      if (municipalityId != null) 'municipality_id': municipalityId,
      if (q != null && q!.isNotEmpty) 'q': q,
      'sort': sort,
      if (isLand && lalpurjaAvailable != null) 'lalpurja_available': lalpurjaAvailable,
      if (isLand && roadAccess != null) 'road_access': roadAccess,
    };
  }
}

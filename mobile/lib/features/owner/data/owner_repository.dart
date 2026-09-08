import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../listings/data/models/land_profile.dart';
import '../../listings/data/models/listing_detail.dart';
import '../../listings/data/models/media_item.dart';
import '../../listings/data/models/property.dart';
import 'models/listing_analytics.dart';

/// Talks to the owner/agent surface: `/owner/*`, `/properties/*`. Every
/// mutation here mirrors a real, separate backend endpoint — the
/// Post-Property Wizard is a multi-step flow, not one atomic submission
/// (see backend/app/Http/Controllers/Api/V1/Owner/*Controller.php).
class OwnerRepository {
  OwnerRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<PaginatedResult<Property>> myProperties({int page = 1}) async {
    try {
      final response = await _dio.get('/owner/properties', queryParameters: {'page': page});
      return PaginatedResult.fromJson(response.data as Map<String, dynamic>, Property.fromJson);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Step 1 of the wizard: creates the `Property` + its `Address` in one
  /// call. `propertyType` decides which of `bedrooms`/`bathrooms` are
  /// required server-side (room/apartment/house only).
  Future<Property> createProperty({
    required String propertyType,
    required double areaValue,
    required String areaUnit,
    int? bedrooms,
    int? bathrooms,
    int? floors,
    int? yearBuilt,
    int? parkingSpaces,
    String? parkingType,
    String? isFurnished,
    required int provinceId,
    required int districtId,
    required int municipalityId,
    required int wardId,
    int? neighborhoodId,
    String? streetAddress,
    String? landmark,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.post(
        '/properties',
        data: {
          'property_type': propertyType,
          'area_value': areaValue,
          'area_unit': areaUnit,
          'bedrooms': ?bedrooms,
          'bathrooms': ?bathrooms,
          'floors': ?floors,
          'year_built': ?yearBuilt,
          'parking_spaces': ?parkingSpaces,
          'parking_type': ?parkingType,
          'is_furnished': ?isFurnished,
          'address': {
            'province_id': provinceId,
            'district_id': districtId,
            'municipality_id': municipalityId,
            'ward_id': wardId,
            'neighborhood_id': ?neighborhoodId,
            if (streetAddress != null && streetAddress.isNotEmpty) 'street_address': streetAddress,
            if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
            'lat': ?lat,
            'lng': ?lng,
          },
        },
      );
      return Property.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Land branch only. `PUT` behaves as an upsert with all fields optional
  /// (`updateOrCreate([], $validated)` server-side) — pass only what changed.
  Future<LandProfile> saveLandProfile(int propertyId, Map<String, dynamic> fields) async {
    try {
      final response = await _dio.put('/properties/$propertyId/land-profile', data: fields);
      return LandProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<LandProfile> uploadLandDocument(int propertyId, String filePath) async {
    try {
      final response = await _dio.post(
        '/properties/$propertyId/land-profile/document',
        data: FormData.fromMap({'file': await MultipartFile.fromFile(filePath)}),
      );
      return LandProfile.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Appends one media file (photo, by far the common case in the wizard's
  /// Media step) — there's no batch-upload or reorder endpoint, only
  /// append-one/delete-one, with `sort_order` assigned server-side.
  Future<MediaItem> uploadMedia(int propertyId, String filePath, {String type = 'image'}) async {
    try {
      final response = await _dio.post(
        '/properties/$propertyId/media',
        data: FormData.fromMap({'type': type, 'file': await MultipartFile.fromFile(filePath)}),
      );
      return MediaItem.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteMedia(int propertyId, int mediaId) async {
    try {
      await _dio.delete('/properties/$propertyId/media/$mediaId');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// Step 5 of the wizard: creates the `PropertyListing` (always starts as
  /// `draft`, regardless of what happens next — "submit for review" is a
  /// separate [transitionListing] call).
  Future<ListingDetail> createListing(
    int propertyId, {
    required String purpose,
    required double price,
    String? pricePeriod,
    bool negotiable = false,
    DateTime? availabilityDate,
    required String title,
    String? description,
    List<int> amenityIds = const [],
  }) async {
    try {
      final response = await _dio.post(
        '/properties/$propertyId/listings',
        data: {
          'purpose': purpose,
          'price': price,
          'price_period': ?pricePeriod,
          'negotiable': negotiable,
          if (availabilityDate != null) 'availability_date': _dateOnly(availabilityDate),
          'title': title,
          if (description != null && description.isNotEmpty) 'description': description,
          if (amenityIds.isNotEmpty) 'amenity_ids': amenityIds,
        },
      );
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<ListingDetail> ownerListing(int listingId) async {
    try {
      final response = await _dio.get('/owner/listings/$listingId');
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// `purpose` is deliberately not accepted here — only listing-level fields
  /// (price/title/description/amenities/etc) can change after posting;
  /// property fields (address/area/bedrooms) are immutable via this route.
  /// The `PUT` verb behaves like a `PATCH`: every field is optional.
  Future<ListingDetail> updateListing(
    int listingId, {
    double? price,
    String? pricePeriod,
    bool? negotiable,
    DateTime? availabilityDate,
    bool clearAvailabilityDate = false,
    String? title,
    String? description,
    List<int>? amenityIds,
  }) async {
    try {
      final response = await _dio.put(
        '/owner/listings/$listingId',
        data: {
          'price': ?price,
          'price_period': ?pricePeriod,
          'negotiable': ?negotiable,
          if (clearAvailabilityDate)
            'availability_date': null
          else if (availabilityDate != null)
            'availability_date': _dateOnly(availabilityDate),
          'title': ?title,
          'description': ?description,
          'amenity_ids': ?amenityIds,
        },
      );
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  /// action: submit | pause | resume | mark_rented | mark_sold | withdraw.
  Future<ListingDetail> transitionListing(int listingId, String action) async {
    try {
      final response = await _dio.patch('/owner/listings/$listingId/transition', data: {'action': action});
      return ListingDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<ListingAnalytics> analytics(int listingId) async {
    try {
      final response = await _dio.get('/owner/listings/$listingId/analytics');
      return ListingAnalytics.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

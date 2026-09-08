import '../../../../core/network/json_parsing.dart';

/// Mirrors `PropertyRequestResource`. Deliberately carries no contact
/// info for the poster (name only) — contact happens via messaging.
class PropertyRequest {
  PropertyRequest({
    required this.id,
    required this.purpose,
    this.propertyType,
    this.budgetMin,
    this.budgetMax,
    this.bedroomsMin,
    this.municipality,
    this.notes,
    required this.status,
    this.postedBy,
    required this.isMine,
    required this.createdAt,
  });

  factory PropertyRequest.fromJson(Map<String, dynamic> json) {
    return PropertyRequest(
      id: asInt(json['id'])!,
      purpose: json['purpose'] as String,
      propertyType: json['property_type'] as String?,
      budgetMin: asInt(json['budget_min']),
      budgetMax: asInt(json['budget_max']),
      bedroomsMin: asInt(json['bedrooms_min']),
      municipality: json['municipality'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      postedBy: json['posted_by'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String purpose; // sale | rent
  final String? propertyType;
  final int? budgetMin;
  final int? budgetMax;
  final int? bedroomsMin;
  final String? municipality;
  final String? notes;
  final String status; // open | closed
  final String? postedBy;
  final bool isMine;
  final String createdAt;

  bool get isOpen => status == 'open';
}

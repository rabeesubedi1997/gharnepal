/// Mirrors `Admin\AgencyResource` — `GET /admin/agencies`, `PATCH
/// /admin/agencies/{id}/verify`, `PATCH /admin/agencies/{id}/suspend`.
/// `member_count` is a plain int (no decimal-cast quirk).
class AdminAgency {
  AdminAgency({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    this.registrationNumber,
    required this.status,
    required this.isVerified,
    this.verifiedAt,
    required this.memberCount,
    required this.createdAt,
  });

  factory AdminAgency.fromJson(Map<String, dynamic> json) {
    return AdminAgency(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      registrationNumber: json['registration_number'] as String?,
      status: json['status'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final String? registrationNumber;
  final String status; // active | suspended | pending
  final bool isVerified;
  final String? verifiedAt;
  final int memberCount;
  final String createdAt;
}

const kAdminAgencyStatuses = ['active', 'suspended', 'pending'];

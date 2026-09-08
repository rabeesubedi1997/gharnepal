import '../../../../../core/network/media_url.dart';

/// The submitter, embedded on the admin list view only — the consumer-facing
/// `UserVerification` (lib/features/verifications) has no `user` field since
/// it's always the current user there.
class VerificationSubmitter {
  VerificationSubmitter({required this.id, required this.name, required this.email});

  factory VerificationSubmitter.fromJson(Map<String, dynamic> json) {
    return VerificationSubmitter(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  final int id;
  final String name;
  final String email;
}

/// Mirrors `Admin\UserVerificationResource` — the admin-review shape of the
/// same KYC submission the consumer-facing Verification Center shows, plus
/// the submitter identity an admin needs to review it.
class AdminUserVerification {
  AdminUserVerification({
    required this.id,
    required this.user,
    required this.type,
    required this.status,
    this.documentUrl,
    this.documentMimeType,
    this.rejectionReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory AdminUserVerification.fromJson(Map<String, dynamic> json) {
    return AdminUserVerification(
      id: json['id'] as int,
      user: json['user'] != null ? VerificationSubmitter.fromJson(json['user'] as Map<String, dynamic>) : null,
      type: json['type'] as String,
      status: json['status'] as String,
      documentUrl: json['document_url'] != null ? resolveMediaUrl(json['document_url'] as String) : null,
      documentMimeType: json['document_mime_type'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final VerificationSubmitter? user;
  final String type; // identity | agent_license | agency_document
  final String status; // pending | approved | rejected
  final String? documentUrl;
  final String? documentMimeType;
  final String? rejectionReason;
  final String? reviewedAt;
  final String createdAt;

  bool get isImage => documentMimeType?.startsWith('image/') ?? false;
}

/// The status filter values the admin list supports, defaulting to `pending`
/// (also the server's own default when the query param is omitted).
const kAdminVerificationStatuses = ['pending', 'approved', 'rejected'];

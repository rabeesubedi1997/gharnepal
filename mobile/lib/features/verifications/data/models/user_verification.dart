import '../../../../core/network/media_url.dart';

/// Mirrors `UserVerificationResource` — user-level identity/credential KYC,
/// distinct from Phase 4's land-document verification and from viewing-visit
/// verification.
class UserVerification {
  UserVerification({
    required this.id,
    required this.type,
    required this.status,
    this.documentUrl,
    this.documentMimeType,
    this.rejectionReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      id: json['id'] as int,
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
  final String type; // identity | agent_license | agency_document
  final String status; // pending | approved | rejected
  final String? documentUrl;
  final String? documentMimeType;
  final String? rejectionReason;
  final String? reviewedAt;
  final String createdAt;

  bool get isImage => documentMimeType?.startsWith('image/') ?? false;
}

/// The three submittable document types, with the labels the wizard shows.
const kVerificationTypes = {
  'identity': 'Identity document',
  'agent_license': 'Agent license',
  'agency_document': 'Agency document',
};

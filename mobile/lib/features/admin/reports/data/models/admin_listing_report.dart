/// The abbreviated `listing` object nested on `ListingReportResource` — all
/// fields nullable per the contract (the listing may have been deleted).
class ReportedListingRef {
  ReportedListingRef({this.id, this.slug, this.title});

  factory ReportedListingRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ReportedListingRef();
    return ReportedListingRef(
      id: json['id'] as int?,
      slug: json['slug'] as String?,
      title: json['title'] as String?,
    );
  }

  final int? id;
  final String? slug;
  final String? title;
}

/// The abbreviated `reported_by` object nested on `ListingReportResource`.
class ReportedByRef {
  ReportedByRef({required this.id, required this.name});

  factory ReportedByRef.fromJson(Map<String, dynamic> json) {
    return ReportedByRef(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Mirrors `ListingReportResource` — `GET /admin/reports`, `PATCH
/// /admin/reports/{id}/resolve`.
class AdminListingReport {
  AdminListingReport({
    required this.id,
    required this.listing,
    this.reportedBy,
    required this.reason,
    this.details,
    required this.status,
    this.resolutionNote,
    required this.createdAt,
  });

  factory AdminListingReport.fromJson(Map<String, dynamic> json) {
    return AdminListingReport(
      id: json['id'] as int,
      listing: ReportedListingRef.fromJson(json['listing'] as Map<String, dynamic>?),
      reportedBy: json['reported_by'] != null
          ? ReportedByRef.fromJson(json['reported_by'] as Map<String, dynamic>)
          : null,
      reason: json['reason'] as String,
      details: json['details'] as String?,
      status: json['status'] as String,
      resolutionNote: json['resolution_note'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final ReportedListingRef listing;
  final ReportedByRef? reportedBy;
  final String reason; // fraud | duplicate | sold_already | misleading | inappropriate | other
  final String? details;
  final String status; // open | reviewed | dismissed | action_taken
  final String? resolutionNote;
  final String createdAt;
}

const kAdminReportStatuses = ['open', 'reviewed', 'dismissed', 'action_taken'];

const kAdminReportReasonLabels = {
  'fraud': 'Fraud',
  'duplicate': 'Duplicate',
  'sold_already': 'Sold already',
  'misleading': 'Misleading',
  'inappropriate': 'Inappropriate',
  'other': 'Other',
};

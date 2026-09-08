import '../../../../core/network/json_parsing.dart';

class ViewingRequestListingRef {
  ViewingRequestListingRef({required this.id, required this.slug, required this.title});

  factory ViewingRequestListingRef.fromJson(Map<String, dynamic> json) {
    return ViewingRequestListingRef(
      id: asInt(json['id'])!,
      slug: json['slug'] as String,
      title: json['title'] as String,
    );
  }

  final int id;
  final String slug;
  final String title;
}

class ViewingRequestPerson {
  ViewingRequestPerson({required this.id, required this.name});

  factory ViewingRequestPerson.fromJson(Map<String, dynamic> json) {
    return ViewingRequestPerson(id: asInt(json['id'])!, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Mirrors the `visit_verification` object on `ViewingRequestResource` —
/// present only on `index` and right after submitting one (absent, not
/// null, on `store`/`transition`).
class VisitVerification {
  VisitVerification({
    required this.visited,
    this.matchedListing,
    this.priceAccurate,
    this.hostAttended,
    this.documentsShown,
    this.overallComment,
  });

  factory VisitVerification.fromJson(Map<String, dynamic> json) {
    return VisitVerification(
      visited: json['visited'] as bool? ?? false,
      matchedListing: json['matched_listing'] as bool?,
      priceAccurate: json['price_accurate'] as bool?,
      hostAttended: json['host_attended'] as bool?,
      documentsShown: json['documents_shown'] as bool?,
      overallComment: json['overall_comment'] as String?,
    );
  }

  final bool visited;
  final bool? matchedListing;
  final bool? priceAccurate;
  final bool? hostAttended;
  final bool? documentsShown;
  final String? overallComment;
}

/// Mirrors `ViewingRequestResource`.
class ViewingRequest {
  ViewingRequest({
    required this.id,
    required this.listing,
    this.requester,
    this.host,
    required this.proposedDatetime,
    this.confirmedDatetime,
    required this.status,
    this.notes,
    this.visitVerification,
    required this.createdAt,
  });

  factory ViewingRequest.fromJson(Map<String, dynamic> json) {
    return ViewingRequest(
      id: asInt(json['id'])!,
      listing: ViewingRequestListingRef.fromJson(json['listing'] as Map<String, dynamic>),
      requester: json['requester'] != null
          ? ViewingRequestPerson.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      host: json['host'] != null ? ViewingRequestPerson.fromJson(json['host'] as Map<String, dynamic>) : null,
      proposedDatetime: json['proposed_datetime'] as String,
      confirmedDatetime: json['confirmed_datetime'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      visitVerification: json['visit_verification'] != null
          ? VisitVerification.fromJson(json['visit_verification'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String,
    );
  }

  final int id;
  final ViewingRequestListingRef listing;
  final ViewingRequestPerson? requester;
  final ViewingRequestPerson? host;
  final String proposedDatetime;
  final String? confirmedDatetime;
  final String status; // requested | confirmed | rescheduled | completed | cancelled | no_show
  final String? notes;
  final VisitVerification? visitVerification;
  final String createdAt;
}

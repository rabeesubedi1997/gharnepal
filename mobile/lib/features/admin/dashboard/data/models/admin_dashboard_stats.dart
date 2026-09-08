import '../../../../../core/network/json_parsing.dart';

/// Mirrors the `listings` section of `GET /admin/dashboard/stats`.
class DashboardListingStats {
  DashboardListingStats({
    required this.total,
    required this.published,
    required this.pendingReview,
    required this.featuredActive,
  });

  factory DashboardListingStats.fromJson(Map<String, dynamic> json) {
    return DashboardListingStats(
      total: json['total'] as int? ?? 0,
      published: json['published'] as int? ?? 0,
      pendingReview: json['pending_review'] as int? ?? 0,
      featuredActive: json['featured_active'] as int? ?? 0,
    );
  }

  final int total;
  final int published;
  final int pendingReview;
  final int featuredActive;
}

/// Mirrors the `users` section of `GET /admin/dashboard/stats`.
class DashboardUserStats {
  DashboardUserStats({
    required this.total,
    required this.owners,
    required this.agents,
    required this.suspended,
  });

  factory DashboardUserStats.fromJson(Map<String, dynamic> json) {
    return DashboardUserStats(
      total: json['total'] as int? ?? 0,
      owners: json['owners'] as int? ?? 0,
      agents: json['agents'] as int? ?? 0,
      suspended: json['suspended'] as int? ?? 0,
    );
  }

  final int total;
  final int owners;
  final int agents;
  final int suspended;
}

/// Mirrors the `agencies` section of `GET /admin/dashboard/stats`.
class DashboardAgencyStats {
  DashboardAgencyStats({required this.total, required this.verified, required this.pending});

  factory DashboardAgencyStats.fromJson(Map<String, dynamic> json) {
    return DashboardAgencyStats(
      total: json['total'] as int? ?? 0,
      verified: json['verified'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }

  final int total;
  final int verified;
  final int pending;
}

/// Mirrors the `moderation_queue` section of `GET /admin/dashboard/stats`.
class DashboardModerationQueueStats {
  DashboardModerationQueueStats({
    required this.reports,
    required this.duplicateFlags,
    required this.verifications,
    required this.communityNotes,
  });

  factory DashboardModerationQueueStats.fromJson(Map<String, dynamic> json) {
    return DashboardModerationQueueStats(
      reports: json['reports'] as int? ?? 0,
      duplicateFlags: json['duplicate_flags'] as int? ?? 0,
      verifications: json['verifications'] as int? ?? 0,
      communityNotes: json['community_notes'] as int? ?? 0,
    );
  }

  final int reports;
  final int duplicateFlags;
  final int verifications;
  final int communityNotes;

  int get total => reports + duplicateFlags + verifications + communityNotes;
}

/// Mirrors the `payments` section of `GET /admin/dashboard/stats`.
/// `completed_amount` is a plain (safe) float, not a decimal-cast string.
class DashboardPaymentStats {
  DashboardPaymentStats({
    required this.completedCount,
    required this.completedAmount,
    required this.pending,
  });

  factory DashboardPaymentStats.fromJson(Map<String, dynamic> json) {
    return DashboardPaymentStats(
      completedCount: json['completed_count'] as int? ?? 0,
      completedAmount: asDoubleOr(json['completed_amount'], 0),
      pending: json['pending'] as int? ?? 0,
    );
  }

  final int completedCount;
  final double completedAmount;
  final int pending;
}

/// Mirrors `GET /admin/dashboard/stats`'s `data` object.
class AdminDashboardStats {
  AdminDashboardStats({
    required this.listings,
    required this.users,
    required this.agencies,
    required this.moderationQueue,
    required this.payments,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      listings: DashboardListingStats.fromJson(json['listings'] as Map<String, dynamic>? ?? const {}),
      users: DashboardUserStats.fromJson(json['users'] as Map<String, dynamic>? ?? const {}),
      agencies: DashboardAgencyStats.fromJson(json['agencies'] as Map<String, dynamic>? ?? const {}),
      moderationQueue: DashboardModerationQueueStats.fromJson(
        json['moderation_queue'] as Map<String, dynamic>? ?? const {},
      ),
      payments: DashboardPaymentStats.fromJson(json['payments'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final DashboardListingStats listings;
  final DashboardUserStats users;
  final DashboardAgencyStats agencies;
  final DashboardModerationQueueStats moderationQueue;
  final DashboardPaymentStats payments;
}

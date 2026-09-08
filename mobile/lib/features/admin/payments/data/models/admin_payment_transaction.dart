import '../../../../../core/network/json_parsing.dart';

class AdminPaymentListingRef {
  AdminPaymentListingRef({required this.id, required this.slug, required this.title, this.featuredUntil});

  factory AdminPaymentListingRef.fromJson(Map<String, dynamic> json) {
    return AdminPaymentListingRef(
      id: asInt(json['id'])!,
      slug: json['slug'] as String,
      title: json['title'] as String,
      featuredUntil: json['featured_until'] as String?,
    );
  }

  final int id;
  final String slug;
  final String title;
  final String? featuredUntil;
}

class AdminPaymentUserRef {
  AdminPaymentUserRef({required this.id, required this.name});

  factory AdminPaymentUserRef.fromJson(Map<String, dynamic> json) {
    return AdminPaymentUserRef(id: asInt(json['id'])!, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Mirrors `PaymentTransactionResource` as returned by `/admin/payments`.
/// `amount` is server-cast `(float)` — a safe bare JSON number, no
/// string-parsing quirk (unlike other decimal-backed fields elsewhere in
/// the app) — but `asDoubleOr` is used defensively regardless.
class AdminPaymentTransaction {
  AdminPaymentTransaction({
    required this.id,
    required this.planKey,
    required this.planDays,
    required this.amount,
    required this.currency,
    required this.gateway,
    required this.gatewayReference,
    required this.status,
    this.completedAt,
    required this.createdAt,
    this.listing,
    this.user,
  });

  factory AdminPaymentTransaction.fromJson(Map<String, dynamic> json) {
    return AdminPaymentTransaction(
      id: asInt(json['id'])!,
      planKey: json['plan_key'] as String,
      planDays: asInt(json['plan_days']) ?? 0,
      amount: asDoubleOr(json['amount'], 0),
      currency: json['currency'] as String? ?? 'NPR',
      gateway: json['gateway'] as String,
      gatewayReference: json['gateway_reference'] as String,
      status: json['status'] as String,
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
      listing: json['listing'] != null
          ? AdminPaymentListingRef.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null ? AdminPaymentUserRef.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  final int id;
  final String planKey;
  final int planDays;
  final double amount;
  final String currency;
  final String gateway;
  final String gatewayReference;
  final String status; // pending | completed | failed | refunded
  final String? completedAt;
  final String createdAt;
  final AdminPaymentListingRef? listing;
  final AdminPaymentUserRef? user;
}

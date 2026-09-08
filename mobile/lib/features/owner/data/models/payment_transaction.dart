import '../../../../core/network/json_parsing.dart';

class PaymentTransactionListingRef {
  PaymentTransactionListingRef({required this.id, required this.slug, required this.title, this.featuredUntil});

  factory PaymentTransactionListingRef.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionListingRef(
      id: json['id'] as int,
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

/// Mirrors `PaymentTransactionResource` — both a purchase-initiation/confirm
/// response and a Payment History list item.
class PaymentTransaction {
  PaymentTransaction({
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
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as int,
      planKey: json['plan_key'] as String,
      planDays: json['plan_days'] as int,
      amount: asDoubleOr(json['amount'], 0),
      currency: json['currency'] as String? ?? 'NPR',
      gateway: json['gateway'] as String,
      gatewayReference: json['gateway_reference'] as String,
      status: json['status'] as String,
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
      listing: json['listing'] != null
          ? PaymentTransactionListingRef.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
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
  final PaymentTransactionListingRef? listing;
}

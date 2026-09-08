import '../../../../core/network/json_parsing.dart';

/// `GET /featured-plans` (public) — the sandbox "boost" catalog:
/// App\Domain\Payments\Services\FeaturedListingPlans::PLANS.
class FeaturedPlan {
  FeaturedPlan({required this.key, required this.days, required this.price, required this.label});

  factory FeaturedPlan.fromJson(Map<String, dynamic> json) {
    return FeaturedPlan(
      key: json['key'] as String,
      days: json['days'] as int,
      price: asDoubleOr(json['price'], 0),
      label: json['label'] as String,
    );
  }

  final String key; // boost_7 | boost_15 | boost_30
  final int days;
  final double price;
  final String label;
}

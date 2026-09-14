import '../../../../core/network/json_parsing.dart';

/// One row of `land_price_per_aana_by_city` — a live per-city median (not a
/// fabricated multi-year "index"), see `PlatformStatsController.php`.
class LandPriceByCity {
  LandPriceByCity({required this.municipality, required this.medianPricePerAana, required this.listingCount});

  factory LandPriceByCity.fromJson(Map<String, dynamic> json) {
    return LandPriceByCity(
      municipality: json['municipality'] as String,
      medianPricePerAana: asInt(json['median_price_per_aana']) ?? 0,
      listingCount: json['listing_count'] as int? ?? 0,
    );
  }

  final String municipality;
  final int medianPricePerAana;
  final int listingCount;
}

/// Mirrors `GET /platform-stats` — real, computed platform-wide figures for
/// the homepage's trust/transparency strip and alert-signup subscriber
/// count. Public, no auth, cached 15 min server-side.
class PlatformStats {
  PlatformStats({
    required this.publishedListings,
    required this.verifiedAgencies,
    required this.phoneVerifiedOwnerPct,
    required this.citiesCovered,
    required this.activeAlertSubscriptions,
    required this.landPricePerAanaByCity,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      publishedListings: json['published_listings'] as int? ?? 0,
      verifiedAgencies: json['verified_agencies'] as int? ?? 0,
      phoneVerifiedOwnerPct: json['phone_verified_owner_pct'] as int? ?? 0,
      citiesCovered: json['cities_covered'] as int? ?? 0,
      activeAlertSubscriptions: json['active_alert_subscriptions'] as int? ?? 0,
      landPricePerAanaByCity: (json['land_price_per_aana_by_city'] as List<dynamic>? ?? const [])
          .map((c) => LandPriceByCity.fromJson(c as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int publishedListings;
  final int verifiedAgencies;
  final int phoneVerifiedOwnerPct;
  final int citiesCovered;
  final int activeAlertSubscriptions;
  final List<LandPriceByCity> landPricePerAanaByCity;
}

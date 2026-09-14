import '../../../../core/network/json_parsing.dart';
import '../../../../core/network/media_url.dart';

class AgencyDashboardAgency {
  AgencyDashboardAgency({
    required this.name,
    required this.slug,
    this.logoUrl,
    this.registrationNumber,
    this.foundedYear,
    required this.isVerified,
    required this.memberCount,
  });

  factory AgencyDashboardAgency.fromJson(Map<String, dynamic> json) {
    return AgencyDashboardAgency(
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] != null ? resolveMediaUrl(json['logo_url'] as String) : null,
      registrationNumber: json['registration_number'] as String?,
      foundedYear: json['founded_year'] as int?,
      isVerified: json['is_verified'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  final String name;
  final String slug;
  final String? logoUrl;
  final String? registrationNumber;
  final int? foundedYear;
  final bool isVerified;
  final int memberCount;
}

class AgencyCityCount {
  AgencyCityCount({required this.city, required this.count});

  factory AgencyCityCount.fromJson(Map<String, dynamic> json) {
    return AgencyCityCount(city: json['city'] as String, count: json['count'] as int? ?? 0);
  }

  final String city;
  final int count;
}

class AgencyPortfolio {
  AgencyPortfolio({required this.activeCount, required this.newThisWeek, required this.byCity});

  factory AgencyPortfolio.fromJson(Map<String, dynamic> json) {
    return AgencyPortfolio(
      activeCount: json['active_count'] as int? ?? 0,
      newThisWeek: json['new_this_week'] as int? ?? 0,
      byCity: (json['by_city'] as List<dynamic>? ?? const [])
          .map((c) => AgencyCityCount.fromJson(c as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int activeCount;
  final int newThisWeek;
  final List<AgencyCityCount> byCity;
}

class AgencyInquiriesSummary {
  AgencyInquiriesSummary({required this.count, this.responseRatePct});

  factory AgencyInquiriesSummary.fromJson(Map<String, dynamic> json) {
    return AgencyInquiriesSummary(
      count: json['count'] as int? ?? 0,
      responseRatePct: json['response_rate_pct'] as int?,
    );
  }

  final int count;
  final int? responseRatePct;
}

class AgencySiteVisitsSummary {
  AgencySiteVisitsSummary({required this.upcoming7d, required this.today});

  factory AgencySiteVisitsSummary.fromJson(Map<String, dynamic> json) {
    return AgencySiteVisitsSummary(upcoming7d: json['upcoming_7d'] as int? ?? 0, today: json['today'] as int? ?? 0);
  }

  final int upcoming7d;
  final int today;
}

class AgencyPortfolioValue {
  AgencyPortfolioValue({required this.total, required this.listingCount});

  factory AgencyPortfolioValue.fromJson(Map<String, dynamic> json) {
    return AgencyPortfolioValue(
      total: asDoubleOr(json['total'], 0),
      listingCount: json['listing_count'] as int? ?? 0,
    );
  }

  final double total;
  final int listingCount;
}

/// Mirrors `Agency\DashboardController::overview` — `GET /agency/dashboard/overview`.
class AgencyOverview {
  AgencyOverview({
    required this.agency,
    required this.portfolio,
    required this.inquiries30d,
    required this.siteVisits,
    required this.forSalePortfolioValue,
    required this.alertReach,
  });

  factory AgencyOverview.fromJson(Map<String, dynamic> json) {
    return AgencyOverview(
      agency: AgencyDashboardAgency.fromJson(json['agency'] as Map<String, dynamic>),
      portfolio: AgencyPortfolio.fromJson(json['portfolio'] as Map<String, dynamic>),
      inquiries30d: AgencyInquiriesSummary.fromJson(json['inquiries_30d'] as Map<String, dynamic>),
      siteVisits: AgencySiteVisitsSummary.fromJson(json['site_visits'] as Map<String, dynamic>),
      forSalePortfolioValue: AgencyPortfolioValue.fromJson(json['for_sale_portfolio_value'] as Map<String, dynamic>),
      alertReach: json['alert_reach'] as int? ?? 0,
    );
  }

  final AgencyDashboardAgency agency;
  final AgencyPortfolio portfolio;
  final AgencyInquiriesSummary inquiries30d;
  final AgencySiteVisitsSummary siteVisits;
  final AgencyPortfolioValue forSalePortfolioValue;
  final int alertReach;
}

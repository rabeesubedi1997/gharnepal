import '../../../../core/network/json_parsing.dart';

/// The `rating` object shared by both `PropertyListingSummaryResource` and
/// `PropertyListingDetailResource`.
class RatingSummary {
  RatingSummary({required this.average, required this.count});

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(average: asDouble(json['average']), count: asInt(json['count']) ?? 0);
  }

  final double? average;
  final int count;
}

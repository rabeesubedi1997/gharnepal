import '../../../../core/network/json_parsing.dart';

/// Mirrors `RentalCostCalculator::calculate()`'s return array exactly —
/// every field here is a real JSON number (plain PHP floats, no decimal
/// casts involved).
class RentalCalculatorResult {
  RentalCalculatorResult({
    required this.monthlyRent,
    required this.utilitiesMonthly,
    required this.internetMonthly,
    required this.parkingMonthly,
    required this.maintenanceMonthly,
    required this.deposit,
    required this.brokerageFee,
    required this.movingCostEstimate,
    required this.monthlyRecurringTotal,
    required this.oneTimeTotal,
    required this.firstMonthTotal,
  });

  factory RentalCalculatorResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? const {};
    return RentalCalculatorResult(
      monthlyRent: asDoubleOr(breakdown['monthly_rent'], 0),
      utilitiesMonthly: asDoubleOr(breakdown['utilities_monthly'], 0),
      internetMonthly: asDoubleOr(breakdown['internet_monthly'], 0),
      parkingMonthly: asDoubleOr(breakdown['parking_monthly'], 0),
      maintenanceMonthly: asDoubleOr(breakdown['maintenance_monthly'], 0),
      deposit: asDoubleOr(breakdown['deposit'], 0),
      brokerageFee: asDoubleOr(breakdown['brokerage_fee'], 0),
      movingCostEstimate: asDoubleOr(breakdown['moving_cost_estimate'], 0),
      monthlyRecurringTotal: asDoubleOr(json['monthly_recurring_total'], 0),
      oneTimeTotal: asDoubleOr(json['one_time_total'], 0),
      firstMonthTotal: asDoubleOr(json['first_month_total'], 0),
    );
  }

  final double monthlyRent;
  final double utilitiesMonthly;
  final double internetMonthly;
  final double parkingMonthly;
  final double maintenanceMonthly;
  final double deposit;
  final double brokerageFee;
  final double movingCostEstimate;
  final double monthlyRecurringTotal;
  final double oneTimeTotal;
  final double firstMonthTotal;
}

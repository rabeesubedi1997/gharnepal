import '../../../../core/network/json_parsing.dart';

/// Mirrors `PurchaseCostCalculator::calculate()`'s return array. Registration/
/// legal-fee percentages are user-adjustable estimates, not an authoritative
/// tax quote — label them as such in the UI, matching the backend's own
/// doc comment.
class PurchaseCalculatorResult {
  PurchaseCalculatorResult({
    required this.propertyPrice,
    required this.downPayment,
    required this.loanAmount,
    required this.registrationCost,
    required this.legalFees,
    required this.renovationEstimate,
    required this.monthlyRepaymentEstimate,
    required this.totalUpfrontCost,
    this.rentalYieldPercent,
    required this.loanInterestRateAnnual,
    required this.loanTenureYears,
    required this.registrationCostPercent,
  });

  factory PurchaseCalculatorResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>? ?? const {};
    final assumptions = json['assumptions'] as Map<String, dynamic>? ?? const {};
    return PurchaseCalculatorResult(
      propertyPrice: asDoubleOr(breakdown['property_price'], 0),
      downPayment: asDoubleOr(breakdown['down_payment'], 0),
      loanAmount: asDoubleOr(breakdown['loan_amount'], 0),
      registrationCost: asDoubleOr(breakdown['registration_cost'], 0),
      legalFees: asDoubleOr(breakdown['legal_fees'], 0),
      renovationEstimate: asDoubleOr(breakdown['renovation_estimate'], 0),
      monthlyRepaymentEstimate: asDoubleOr(json['monthly_repayment_estimate'], 0),
      totalUpfrontCost: asDoubleOr(json['total_upfront_cost'], 0),
      rentalYieldPercent: asDouble(json['rental_yield_percent']),
      loanInterestRateAnnual: asDoubleOr(assumptions['loan_interest_rate_annual'], 10),
      loanTenureYears: asDoubleOr(assumptions['loan_tenure_years'], 20),
      registrationCostPercent: asDoubleOr(assumptions['registration_cost_percent'], 4),
    );
  }

  final double propertyPrice;
  final double downPayment;
  final double loanAmount;
  final double registrationCost;
  final double legalFees;
  final double renovationEstimate;
  final double monthlyRepaymentEstimate;
  final double totalUpfrontCost;
  final double? rentalYieldPercent;
  final double loanInterestRateAnnual;
  final double loanTenureYears;
  final double registrationCostPercent;
}

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/calculator_scenario.dart';
import 'models/purchase_calculator_result.dart';
import 'models/rental_calculator_result.dart';

/// A calculate response bundles the computed result with the saved
/// `CalculatorScenario` when `save: true` was passed (and the caller was
/// logged in) — `scenario` is null for guests or when not saving.
class RentalCalculation {
  RentalCalculation({required this.result, this.scenario});

  final RentalCalculatorResult result;
  final CalculatorScenario? scenario;
}

class PurchaseCalculation {
  PurchaseCalculation({required this.result, this.scenario});

  final PurchaseCalculatorResult result;
  final CalculatorScenario? scenario;
}

/// Talks to `/calculators/*` (guest-accessible, opt-in save when logged in)
/// and `/account/calculator-scenarios` (auth required).
class CalculatorsRepository {
  CalculatorsRepository({required ApiClient apiClient}) : _dio = apiClient.dio;

  final Dio _dio;

  Future<RentalCalculation> calculateRental({
    required double monthlyRent,
    double? depositMonths,
    double? utilitiesMonthly,
    double? internetMonthly,
    double? parkingMonthly,
    double? maintenanceMonthly,
    double? brokerageFee,
    double? movingCostEstimate,
    bool save = false,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/calculators/rental',
        data: {
          'monthly_rent': monthlyRent,
          'deposit_months': ?depositMonths,
          'utilities_monthly': ?utilitiesMonthly,
          'internet_monthly': ?internetMonthly,
          'parking_monthly': ?parkingMonthly,
          'maintenance_monthly': ?maintenanceMonthly,
          'brokerage_fee': ?brokerageFee,
          'moving_cost_estimate': ?movingCostEstimate,
          'save': save,
          if (save && name != null && name.isNotEmpty) 'name': name,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return RentalCalculation(
        result: RentalCalculatorResult.fromJson(data['result'] as Map<String, dynamic>),
        scenario: data['scenario'] != null
            ? CalculatorScenario.fromJson(data['scenario'] as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<PurchaseCalculation> calculatePurchase({
    required double propertyPrice,
    double? downPaymentPercent,
    double? loanInterestRateAnnual,
    double? loanTenureYears,
    double? registrationCostPercent,
    double? legalFees,
    double? renovationEstimate,
    double? monthlyRentEstimate,
    bool save = false,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        '/calculators/purchase',
        data: {
          'property_price': propertyPrice,
          'down_payment_percent': ?downPaymentPercent,
          'loan_interest_rate_annual': ?loanInterestRateAnnual,
          'loan_tenure_years': ?loanTenureYears,
          'registration_cost_percent': ?registrationCostPercent,
          'legal_fees': ?legalFees,
          'renovation_estimate': ?renovationEstimate,
          'monthly_rent_estimate': ?monthlyRentEstimate,
          'save': save,
          if (save && name != null && name.isNotEmpty) 'name': name,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseCalculation(
        result: PurchaseCalculatorResult.fromJson(data['result'] as Map<String, dynamic>),
        scenario: data['scenario'] != null
            ? CalculatorScenario.fromJson(data['scenario'] as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<List<CalculatorScenario>> listScenarios() async {
    try {
      final response = await _dio.get('/account/calculator-scenarios');
      return (response.data['data'] as List<dynamic>)
          .map((s) => CalculatorScenario.fromJson(s as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  Future<void> deleteScenario(int id) async {
    try {
      await _dio.delete('/account/calculator-scenarios/$id');
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}

<?php

namespace App\Domain\Calculators\Services;

/**
 * Stateless purchase-cost calculator. Registration/legal-fee percentages are
 * user-adjustable estimates (Nepal's actual registration duty varies by
 * province, municipality, and declared land value) — we deliberately don't
 * hardcode an authoritative tax rate here; the UI must label these as
 * estimates, not a legal quote.
 */
class PurchaseCostCalculator
{
    public function calculate(array $input): array
    {
        $price = (float) ($input['property_price'] ?? 0);
        $downPaymentPercent = (float) ($input['down_payment_percent'] ?? 20);
        $annualInterestRate = (float) ($input['loan_interest_rate_annual'] ?? 10);
        $tenureYears = (float) ($input['loan_tenure_years'] ?? 20);
        $registrationCostPercent = (float) ($input['registration_cost_percent'] ?? 4);
        $legalFees = (float) ($input['legal_fees'] ?? 0);
        $renovationEstimate = (float) ($input['renovation_estimate'] ?? 0);
        $monthlyRentEstimate = isset($input['monthly_rent_estimate']) ? (float) $input['monthly_rent_estimate'] : null;

        $downPayment = round($price * $downPaymentPercent / 100, 2);
        $loanAmount = round($price - $downPayment, 2);
        $registrationCost = round($price * $registrationCostPercent / 100, 2);

        $monthlyRepayment = $this->monthlyRepayment($loanAmount, $annualInterestRate, $tenureYears);

        $totalUpfrontCost = round($downPayment + $registrationCost + $legalFees + $renovationEstimate, 2);

        $rentalYieldPercent = ($monthlyRentEstimate !== null && $price > 0)
            ? round(($monthlyRentEstimate * 12) / $price * 100, 2)
            : null;

        return [
            'breakdown' => [
                'property_price' => $price,
                'down_payment' => $downPayment,
                'loan_amount' => $loanAmount,
                'registration_cost' => $registrationCost,
                'legal_fees' => $legalFees,
                'renovation_estimate' => $renovationEstimate,
            ],
            'monthly_repayment_estimate' => $monthlyRepayment,
            'total_upfront_cost' => $totalUpfrontCost,
            'rental_yield_percent' => $rentalYieldPercent,
            'assumptions' => [
                'loan_interest_rate_annual' => $annualInterestRate,
                'loan_tenure_years' => $tenureYears,
                'registration_cost_percent' => $registrationCostPercent,
            ],
        ];
    }

    private function monthlyRepayment(float $principal, float $annualRatePercent, float $tenureYears): float
    {
        if ($principal <= 0 || $tenureYears <= 0) {
            return 0.0;
        }

        $months = (int) round($tenureYears * 12);
        $monthlyRate = $annualRatePercent / 100 / 12;

        if ($monthlyRate <= 0) {
            return round($principal / $months, 2);
        }

        $factor = (1 + $monthlyRate) ** $months;
        $emi = $principal * $monthlyRate * $factor / ($factor - 1);

        return round($emi, 2);
    }
}

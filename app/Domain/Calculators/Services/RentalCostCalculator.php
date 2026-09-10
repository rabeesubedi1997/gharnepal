<?php

namespace App\Domain\Calculators\Services;

/**
 * Stateless "true monthly cost" calculator for renters — turns a headline
 * rent figure into what actually leaves your account, including the
 * one-time move-in costs a bare rent price hides.
 */
class RentalCostCalculator
{
    public function calculate(array $input): array
    {
        $monthlyRent = (float) ($input['monthly_rent'] ?? 0);
        $depositMonths = (float) ($input['deposit_months'] ?? 2);
        $utilities = (float) ($input['utilities_monthly'] ?? 0);
        $internet = (float) ($input['internet_monthly'] ?? 0);
        $parking = (float) ($input['parking_monthly'] ?? 0);
        $maintenance = (float) ($input['maintenance_monthly'] ?? 0);
        $brokerageFee = (float) ($input['brokerage_fee'] ?? 0);
        $movingCost = (float) ($input['moving_cost_estimate'] ?? 0);

        $deposit = round($monthlyRent * $depositMonths, 2);
        $monthlyRecurringTotal = round($monthlyRent + $utilities + $internet + $parking + $maintenance, 2);
        $oneTimeTotal = round($deposit + $brokerageFee + $movingCost, 2);
        $firstMonthTotal = round($monthlyRecurringTotal + $oneTimeTotal, 2);

        return [
            'breakdown' => [
                'monthly_rent' => $monthlyRent,
                'utilities_monthly' => $utilities,
                'internet_monthly' => $internet,
                'parking_monthly' => $parking,
                'maintenance_monthly' => $maintenance,
                'deposit' => $deposit,
                'brokerage_fee' => $brokerageFee,
                'moving_cost_estimate' => $movingCost,
            ],
            'monthly_recurring_total' => $monthlyRecurringTotal,
            'one_time_total' => $oneTimeTotal,
            'first_month_total' => $firstMonthTotal,
        ];
    }
}

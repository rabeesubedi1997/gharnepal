<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Calculators\Services\PurchaseCostCalculator;
use App\Domain\Calculators\Services\RentalCostCalculator;
use App\Http\Controllers\Controller;
use App\Http\Resources\CostCalculatorScenarioResource;
use App\Models\CostCalculatorScenario;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CostCalculatorController extends Controller
{
    public function __construct(
        private readonly RentalCostCalculator $rentalCalculator,
        private readonly PurchaseCostCalculator $purchaseCalculator,
    ) {}

    public function rental(Request $request): JsonResponse
    {
        $data = $request->validate([
            'monthly_rent' => ['required', 'numeric', 'min:0'],
            'deposit_months' => ['nullable', 'numeric', 'min:0', 'max:12'],
            'utilities_monthly' => ['nullable', 'numeric', 'min:0'],
            'internet_monthly' => ['nullable', 'numeric', 'min:0'],
            'parking_monthly' => ['nullable', 'numeric', 'min:0'],
            'maintenance_monthly' => ['nullable', 'numeric', 'min:0'],
            'brokerage_fee' => ['nullable', 'numeric', 'min:0'],
            'moving_cost_estimate' => ['nullable', 'numeric', 'min:0'],
            'save' => ['sometimes', 'boolean'],
            'name' => ['nullable', 'string', 'max:255'],
            'listing_id' => ['nullable', 'integer', 'exists:property_listings,id'],
        ]);

        $result = $this->rentalCalculator->calculate($data);

        return $this->respond($request, 'rental', $data, $result);
    }

    public function purchase(Request $request): JsonResponse
    {
        $data = $request->validate([
            'property_price' => ['required', 'numeric', 'min:0'],
            'down_payment_percent' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'loan_interest_rate_annual' => ['nullable', 'numeric', 'min:0', 'max:30'],
            'loan_tenure_years' => ['nullable', 'numeric', 'min:1', 'max:35'],
            'registration_cost_percent' => ['nullable', 'numeric', 'min:0', 'max:20'],
            'legal_fees' => ['nullable', 'numeric', 'min:0'],
            'renovation_estimate' => ['nullable', 'numeric', 'min:0'],
            'monthly_rent_estimate' => ['nullable', 'numeric', 'min:0'],
            'save' => ['sometimes', 'boolean'],
            'name' => ['nullable', 'string', 'max:255'],
            'listing_id' => ['nullable', 'integer', 'exists:property_listings,id'],
        ]);

        $result = $this->purchaseCalculator->calculate($data);

        return $this->respond($request, 'purchase', $data, $result);
    }

    private function respond(Request $request, string $type, array $data, array $result): JsonResponse
    {
        $scenario = null;

        if ($request->user() && $request->boolean('save')) {
            $scenario = CostCalculatorScenario::create([
                'user_id' => $request->user()->id,
                'property_listing_id' => $data['listing_id'] ?? null,
                'type' => $type,
                'name' => $data['name'] ?? null,
                'inputs' => $data,
                'computed_result' => $result,
            ]);
        }

        return response()->json([
            'data' => [
                'result' => $result,
                'scenario' => $scenario ? new CostCalculatorScenarioResource($scenario) : null,
            ],
        ]);
    }
}

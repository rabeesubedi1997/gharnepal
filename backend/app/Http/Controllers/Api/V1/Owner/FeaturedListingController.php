<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Domain\Payments\Services\FeaturedListingPlans;
use App\Domain\Payments\Services\FeaturedListingPurchaseService;
use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentTransactionResource;
use App\Models\PaymentGatewayConfig;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FeaturedListingController extends Controller
{
    public function __construct(private readonly FeaturedListingPurchaseService $purchases) {}

    public function plans(): JsonResponse
    {
        return response()->json(['data' => FeaturedListingPlans::all()]);
    }

    public function store(Request $request, PropertyListing $listing): JsonResponse
    {
        $this->authorize('update', $listing);

        $data = $request->validate([
            'plan_key' => ['required', Rule::in(array_keys(FeaturedListingPlans::PLANS))],
            'gateway_config_id' => [
                'required',
                Rule::exists('payment_gateway_configs', 'id')->where('is_enabled', true),
            ],
        ]);

        $gatewayConfig = PaymentGatewayConfig::findOrFail($data['gateway_config_id']);

        $result = $this->purchases->initiate($listing, $request->user(), $data['plan_key'], $gatewayConfig);

        return (new PaymentTransactionResource($result['transaction']->load('propertyListing')))
            ->additional(['checkout' => [
                'mode' => $result['initiation']->mode,
                'redirect_url' => $result['initiation']->redirectUrl,
                'form_fields' => $result['initiation']->formFields,
                'instructions' => $result['initiation']->instructions,
                // One URL any client can just open externally to actually pay
                // (a browser does the redirect/form-post itself) — what the
                // mobile app uses instead of replicating the frontend's own
                // hidden-form-auto-submit JS.
                'checkout_redirect_url' => $result['initiation']->mode === 'inline'
                    ? null
                    : route('payments.checkout-redirect', ['reference' => $result['transaction']->gateway_reference]),
            ]])
            ->response()->setStatusCode(201);
    }
}

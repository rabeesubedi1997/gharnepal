<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Domain\Payments\Services\FeaturedListingPlans;
use App\Domain\Payments\Services\FeaturedListingPurchaseService;
use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentTransactionResource;
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
        ]);

        $transaction = $this->purchases->initiate($listing, $request->user(), $data['plan_key']);

        return (new PaymentTransactionResource($transaction->load('propertyListing')))->response()->setStatusCode(201);
    }
}

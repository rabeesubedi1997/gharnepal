<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\PublicPaymentGatewayResource;
use App\Models\PaymentGatewayConfig;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * What the checkout screen offers the buyer to pay with — every enabled
 * config, admin's own label, ordered the way the admin arranged them.
 * Never exposes credentials (not even fetched from the database here).
 */
class PaymentGatewayController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $configs = PaymentGatewayConfig::query()
            ->where('is_enabled', true)
            ->orderBy('sort_order')
            ->get(['id', 'provider', 'label', 'is_sandbox']);

        return PublicPaymentGatewayResource::collection($configs);
    }
}

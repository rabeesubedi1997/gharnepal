<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Payments\Services\PaymentGatewayDriverRegistry;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdminPaymentGatewayResource;
use App\Models\PaymentGatewayConfig;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

class PaymentGatewayConfigController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AdminPaymentGatewayResource::collection(
            PaymentGatewayConfig::query()->orderBy('sort_order')->get()
        );
    }

    /** Every supported provider, its display label, and what credential fields its admin form needs — drives the "Add gateway" form generically, no per-provider frontend code. */
    public function catalog(): JsonResponse
    {
        return response()->json(['data' => PaymentGatewayDriverRegistry::catalog()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'provider' => ['required', Rule::in(PaymentGatewayDriverRegistry::providerKeys())],
            'label' => ['required', 'string', 'max:255'],
            'is_enabled' => ['sometimes', 'boolean'],
            'is_sandbox' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'instructions' => ['nullable', 'string', 'max:2000'],
            'credentials' => ['sometimes', 'array'],
        ]);

        $config = PaymentGatewayConfig::create([
            'provider' => $data['provider'],
            'label' => $data['label'],
            'is_enabled' => $request->boolean('is_enabled', false),
            'is_sandbox' => $request->boolean('is_sandbox', true),
            'sort_order' => $data['sort_order'] ?? ((PaymentGatewayConfig::max('sort_order') ?? -1) + 1),
            'instructions' => $data['instructions'] ?? null,
            'credentials' => collect($data['credentials'] ?? [])->filter(fn ($v) => $v !== null && $v !== '')->all(),
        ]);

        return (new AdminPaymentGatewayResource($config))->response()->setStatusCode(201);
    }

    public function update(Request $request, PaymentGatewayConfig $gatewayConfig): AdminPaymentGatewayResource
    {
        $data = $request->validate([
            'label' => ['sometimes', 'string', 'max:255'],
            'is_enabled' => ['sometimes', 'boolean'],
            'is_sandbox' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'instructions' => ['nullable', 'string', 'max:2000'],
            'credentials' => ['sometimes', 'array'],
        ]);

        if (array_key_exists('credentials', $data)) {
            // Merge, don't replace: changing one field shouldn't require
            // retyping every other credential, and a blank value for a
            // given key means "leave this one alone" (same "blank keeps it"
            // pattern as the reCAPTCHA secret key).
            $incoming = collect($data['credentials'])->filter(fn ($v) => $v !== null && $v !== '');
            $data['credentials'] = array_merge($gatewayConfig->credentials ?? [], $incoming->all());
        }

        $gatewayConfig->update($data);

        return new AdminPaymentGatewayResource($gatewayConfig->fresh());
    }

    public function destroy(PaymentGatewayConfig $gatewayConfig): Response
    {
        $gatewayConfig->delete();

        return response()->noContent();
    }
}

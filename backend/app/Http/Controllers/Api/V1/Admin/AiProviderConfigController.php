<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Assistant\Services\AiAssistantDriverRegistry;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdminAiProviderConfigResource;
use App\Models\AiProviderConfig;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Lets an admin plug a real LLM into the AI assistant (see
 * AssistantService::tryLlmDriver) — entirely optional; with no enabled row
 * here the assistant stays on the free rule-based PropertySearchParser.
 * Mirrors PaymentGatewayConfigController, with one difference: only one
 * provider can drive the assistant at a time, so enabling one disables any
 * other (payment gateways can all stay enabled simultaneously as checkout
 * options — this isn't that kind of "multiple options" list).
 */
class AiProviderConfigController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AdminAiProviderConfigResource::collection(
            AiProviderConfig::query()->orderBy('provider')->get()
        );
    }

    /** Every supported provider, its display label, and what credential fields its admin form needs. */
    public function catalog(): JsonResponse
    {
        return response()->json(['data' => AiAssistantDriverRegistry::catalog()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'provider' => ['required', Rule::in(AiAssistantDriverRegistry::providerKeys()), Rule::unique('ai_provider_configs', 'provider')],
            'label' => ['required', 'string', 'max:255'],
            'is_enabled' => ['sometimes', 'boolean'],
            'credentials' => ['sometimes', 'array'],
        ]);

        $config = DB::transaction(function () use ($data, $request) {
            $isEnabled = $request->boolean('is_enabled', false);
            if ($isEnabled) {
                AiProviderConfig::query()->update(['is_enabled' => false]);
            }

            return AiProviderConfig::create([
                'provider' => $data['provider'],
                'label' => $data['label'],
                'is_enabled' => $isEnabled,
                'credentials' => collect($data['credentials'] ?? [])->filter(fn ($v) => $v !== null && $v !== '')->all(),
            ]);
        });

        return (new AdminAiProviderConfigResource($config))->response()->setStatusCode(201);
    }

    public function update(Request $request, AiProviderConfig $aiProviderConfig): AdminAiProviderConfigResource
    {
        $data = $request->validate([
            'label' => ['sometimes', 'string', 'max:255'],
            'is_enabled' => ['sometimes', 'boolean'],
            'credentials' => ['sometimes', 'array'],
        ]);

        if (array_key_exists('credentials', $data)) {
            // Merge, don't replace: changing one field shouldn't require
            // retyping the other, and a blank value means "leave it alone"
            // (same pattern as the payment-gateway credentials).
            $incoming = collect($data['credentials'])->filter(fn ($v) => $v !== null && $v !== '');
            $data['credentials'] = array_merge($aiProviderConfig->credentials ?? [], $incoming->all());
        }

        DB::transaction(function () use ($data, $request, $aiProviderConfig) {
            if ($request->boolean('is_enabled', false) && ! $aiProviderConfig->is_enabled) {
                AiProviderConfig::query()->where('id', '!=', $aiProviderConfig->id)->update(['is_enabled' => false]);
            }
            $aiProviderConfig->update($data);
        });

        return new AdminAiProviderConfigResource($aiProviderConfig->fresh());
    }

    public function destroy(AiProviderConfig $aiProviderConfig): Response
    {
        $aiProviderConfig->delete();

        return response()->noContent();
    }
}

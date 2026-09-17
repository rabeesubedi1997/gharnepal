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
 * config row total can drive the assistant at a time, so enabling one
 * disables any other (payment gateways can all stay enabled simultaneously
 * as checkout options — this isn't that kind of "multiple options" list).
 *
 * Any number of configs can exist and be added freely (including several
 * for the same provider key, e.g. two separate 'custom' agents) — it's
 * only `is_enabled` that's exclusive. Enabling one while another is already
 * enabled is allowed, not rejected: store()/update() disable the previous
 * one automatically and report it back as `meta.disabled_others` so the
 * admin UI can surface a clear "X was switched off because only one AI
 * agent can be active at a time" message instead of silently swapping.
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
            'provider' => ['required', Rule::in(AiAssistantDriverRegistry::providerKeys())],
            'label' => ['required', 'string', 'max:255'],
            'is_enabled' => ['sometimes', 'boolean'],
            'credentials' => ['sometimes', 'array'],
        ]);

        [$config, $disabledOthers] = DB::transaction(function () use ($data, $request) {
            $isEnabled = $request->boolean('is_enabled', false);
            $disabledOthers = $isEnabled ? $this->disableAllOthers(null) : collect();

            $config = AiProviderConfig::create([
                'provider' => $data['provider'],
                'label' => $data['label'],
                'is_enabled' => $isEnabled,
                'credentials' => collect($data['credentials'] ?? [])->filter(fn ($v) => $v !== null && $v !== '')->all(),
            ]);

            return [$config, $disabledOthers];
        });

        return (new AdminAiProviderConfigResource($config))
            ->additional(['meta' => ['disabled_others' => $disabledOthers]])
            ->response()->setStatusCode(201);
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

        $disabledOthers = DB::transaction(function () use ($data, $request, $aiProviderConfig) {
            $disabledOthers = collect();
            if ($request->boolean('is_enabled', false) && ! $aiProviderConfig->is_enabled) {
                $disabledOthers = $this->disableAllOthers($aiProviderConfig->id);
            }
            $aiProviderConfig->update($data);

            return $disabledOthers;
        });

        return (new AdminAiProviderConfigResource($aiProviderConfig->fresh()))
            ->additional(['meta' => ['disabled_others' => $disabledOthers]]);
    }

    /** Disables every other currently-enabled config and reports which ones, for the caller to surface as a "switched off" message. */
    private function disableAllOthers(?int $exceptId): \Illuminate\Support\Collection
    {
        $query = AiProviderConfig::query()->where('is_enabled', true);
        if ($exceptId !== null) {
            $query->where('id', '!=', $exceptId);
        }

        $others = $query->get(['id', 'provider', 'label']);
        if ($others->isNotEmpty()) {
            AiProviderConfig::query()->whereIn('id', $others->pluck('id'))->update(['is_enabled' => false]);
        }

        return $others->map(fn (AiProviderConfig $c) => ['id' => $c->id, 'provider' => $c->provider, 'label' => $c->label])->values();
    }

    public function destroy(AiProviderConfig $aiProviderConfig): Response
    {
        $aiProviderConfig->delete();

        return response()->noContent();
    }
}

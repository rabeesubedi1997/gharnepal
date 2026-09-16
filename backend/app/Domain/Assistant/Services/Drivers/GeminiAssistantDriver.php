<?php

namespace App\Domain\Assistant\Services\Drivers;

use App\Domain\Assistant\Contracts\AiAssistantDriver;
use App\Domain\Assistant\Contracts\AiDriverReply;
use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Domain\Assistant\Services\AssistantToolkit;
use App\Models\AiProviderConfig;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * A real, open-ended conversational backend for the assistant via Google's
 * Gemini API — only used when an admin has configured and enabled a Gemini
 * AiProviderConfig (see AiAssistantDriverRegistry). The default remains the
 * free PropertySearchParser; see ClaudeAssistantDriver's docblock for why
 * this is opt-in, not a default.
 *
 * Uses Laravel's own HTTP client against Gemini's REST `generateContent`
 * endpoint directly rather than a third-party package — there's no single
 * dominant, verified official PHP SDK for Gemini the way anthropic-ai/sdk
 * is for Claude, so a raw call against Google's documented REST shape is
 * the lower-risk choice. `model` is a required admin-supplied credential,
 * same reasoning as OpenAiAssistantDriver: no cached/authoritative current
 * Gemini model list to default to.
 */
class GeminiAssistantDriver implements AiAssistantDriver
{
    private const MAX_TOOL_ROUNDS = 6;

    private const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

    public static function providerKey(): string
    {
        return 'gemini';
    }

    public static function label(): string
    {
        return 'Gemini (Google)';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'api_key', 'label' => 'API Key', 'type' => 'password', 'required' => true],
            ['key' => 'model', 'label' => 'Model (e.g. gemini-2.0-flash)', 'type' => 'text', 'required' => true],
        ];
    }

    public function reply(AiProviderConfig $config, string $message, array $history, AssistantToolkit $toolkit): AiDriverReply
    {
        $apiKey = $config->credential('api_key');
        $model = $config->credential('model');
        if (! $apiKey || ! $model) {
            throw new AiDriverException('Gemini is enabled but is missing its API key or model.');
        }

        $tools = [[
            'functionDeclarations' => array_map(fn (array $t) => [
                'name' => $t['name'],
                'description' => $t['description'],
                'parameters' => $this->sanitizeSchema($t['parameters']),
            ], AssistantToolkit::toolDefinitions()),
        ]];

        // Gemini has no separate "assistant" role — its own turns are 'model'.
        $contents = [
            ...array_map(fn (array $m) => [
                'role' => $m['role'] === 'assistant' ? 'model' : 'user',
                'parts' => [['text' => $m['content']]],
            ], $history),
            ['role' => 'user', 'parts' => [['text' => $message]]],
        ];

        $lastListingIds = [];

        try {
            $rounds = 0;
            while (true) {
                $response = Http::withHeaders(['x-goog-api-key' => $apiKey])
                    ->timeout(30)
                    ->post(self::API_BASE."/{$model}:generateContent", [
                        'system_instruction' => ['parts' => [['text' => $this->systemPrompt($toolkit)]]],
                        'contents' => $contents,
                        'tools' => $tools,
                    ]);

                if ($response->failed()) {
                    throw new AiDriverException('Gemini API error ('.$response->status().'): '.$response->body());
                }

                $parts = $response->json('candidates.0.content.parts') ?? [];
                $functionCalls = array_values(array_filter($parts, fn (array $p) => isset($p['functionCall'])));

                if ($functionCalls === [] || $rounds >= self::MAX_TOOL_ROUNDS) {
                    $text = collect($parts)->pluck('text')->filter()->implode('');

                    return new AiDriverReply(reply: trim($text) !== '' ? $text : "I'm not sure how to help with that — could you rephrase?", listingIds: $lastListingIds);
                }

                $rounds++;
                $contents[] = ['role' => 'model', 'parts' => $parts];

                $responseParts = [];
                foreach ($functionCalls as $part) {
                    $call = $part['functionCall'];
                    [$result, $listingIds] = $this->dispatchTool($toolkit, $call['name'], $call['args'] ?? []);
                    if ($listingIds !== null) {
                        $lastListingIds = $listingIds;
                    }

                    // Gemini requires functionResponse.response to be a JSON
                    // object, never a bare string/array — wrap whatever the
                    // toolkit returned.
                    $responseParts[] = [
                        'functionResponse' => [
                            'name' => $call['name'],
                            'response' => ['content' => $result],
                        ],
                    ];
                }
                $contents[] = ['role' => 'user', 'parts' => $responseParts];
            }
        } catch (AiDriverException $e) {
            throw $e;
        } catch (Throwable $e) {
            throw new AiDriverException('Gemini driver failure: '.$e->getMessage(), previous: $e);
        }
    }

    /**
     * Gemini's function-declaration schema is a restricted OpenAPI-3.0-style
     * subset — `additionalProperties` isn't a recognized field and the
     * whole request is rejected (400 INVALID_ARGUMENT) if it's present
     * anywhere, confirmed against the real API. AssistantToolkit's shared
     * schemas include it (valid JSON Schema, fine for Claude/OpenAI), so
     * strip it recursively before sending to Gemini specifically.
     */
    private function sanitizeSchema(array $schema): array
    {
        unset($schema['additionalProperties']);

        if (isset($schema['properties']) && is_array($schema['properties'])) {
            $schema['properties'] = array_map(
                fn ($prop) => is_array($prop) ? $this->sanitizeSchema($prop) : $prop,
                $schema['properties'],
            );
        }
        if (isset($schema['items']) && is_array($schema['items'])) {
            $schema['items'] = $this->sanitizeSchema($schema['items']);
        }

        return $schema;
    }

    /** @return array{0:mixed,1:?list<int>} [tool result content, listing ids if this was a search] */
    private function dispatchTool(AssistantToolkit $toolkit, string $name, array $input): array
    {
        return match ($name) {
            'search_listings' => (function () use ($toolkit, $input) {
                $result = $toolkit->searchListings($input);

                return [$result['summary_for_model'], $result['listing_ids']];
            })(),
            'resolve_location' => [$toolkit->resolveLocation($input['query'] ?? ''), null],
            'get_listing_detail' => [$toolkit->getListingDetail((int) ($input['id'] ?? 0)) ?? 'No such listing.', null],
            default => ["Unknown tool: {$name}", null],
        };
    }

    private function systemPrompt(AssistantToolkit $toolkit): string
    {
        $amenities = collect($toolkit->amenityCatalog())->map(fn ($a) => "{$a['id']}={$a['name']}")->implode(', ');

        return <<<PROMPT
            You are the Ghar Nepal property-search assistant. Ghar Nepal is a real estate marketplace for Nepal (buy, rent, land, commercial). Help users find real listings via the search_listings, resolve_location, and get_listing_detail tools — never invent a listing, price, or availability that didn't come from a tool result.

            Reply in whichever language and script the user writes in (English, Nepali in Devanagari, or Nepali in Latin script) — match them, don't default to English.

            When a message names a place, call resolve_location first to get a real id before calling search_listings — never guess a location id. If resolve_location returns several plausible candidates, ask the user which one they meant rather than picking arbitrarily.

            Keep replies short and conversational — a sentence or two, not a report. You're scoped to property search on this platform; politely decline unrelated requests (general chit-chat, other topics) and steer back to helping them find a property.

            Amenity ids available for search_listings' amenity_ids filter: {$amenities}
            PROMPT;
    }
}

<?php

namespace App\Domain\Assistant\Services\Drivers;

use App\Domain\Assistant\Contracts\AiAssistantDriver;
use App\Domain\Assistant\Contracts\AiDriverReply;
use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Domain\Assistant\Services\AssistantToolkit;
use App\Models\AiProviderConfig;
use OpenAI\Exceptions\ErrorException;
use Throwable;

/**
 * A real, open-ended conversational backend for the assistant via OpenAI's
 * Chat Completions API — only used when an admin has configured and enabled
 * an OpenAI AiProviderConfig (see AiAssistantDriverRegistry). The default
 * remains the free PropertySearchParser; see ClaudeAssistantDriver's
 * docblock for why this is opt-in, not a default.
 *
 * Unlike Claude, this codebase has no cached model list for OpenAI, so
 * `model` is a required admin-supplied credential rather than a guessed
 * default — the admin explicitly picks (and pays for) whichever model they
 * want.
 */
class OpenAiAssistantDriver implements AiAssistantDriver
{
    private const MAX_TOOL_ROUNDS = 6;

    public static function providerKey(): string
    {
        return 'openai';
    }

    public static function label(): string
    {
        return 'OpenAI';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'api_key', 'label' => 'API Key', 'type' => 'password', 'required' => true],
            ['key' => 'model', 'label' => 'Model (e.g. gpt-4o)', 'type' => 'text', 'required' => true],
        ];
    }

    public function reply(AiProviderConfig $config, string $message, array $history, AssistantToolkit $toolkit): AiDriverReply
    {
        $apiKey = $config->credential('api_key');
        $model = $config->credential('model');
        if (! $apiKey || ! $model) {
            throw new AiDriverException('OpenAI is enabled but is missing its API key or model.');
        }

        $client = \OpenAI::client($apiKey);

        $tools = array_map(fn (array $t) => [
            'type' => 'function',
            'function' => [
                'name' => $t['name'],
                'description' => $t['description'],
                'parameters' => $t['parameters'],
            ],
        ], AssistantToolkit::toolDefinitions());

        $messages = [
            ['role' => 'system', 'content' => $this->systemPrompt($toolkit)],
            ...array_map(fn (array $m) => ['role' => $m['role'], 'content' => $m['content']], $history),
            ['role' => 'user', 'content' => $message],
        ];

        $lastListingIds = [];

        try {
            $response = $client->chat()->create(['model' => $model, 'messages' => $messages, 'tools' => $tools]);

            $rounds = 0;
            $choice = $response->choices[0];

            while ($choice->message->toolCalls !== [] && $rounds < self::MAX_TOOL_ROUNDS) {
                $rounds++;
                $messages[] = $choice->message->toArray();

                foreach ($choice->message->toolCalls as $call) {
                    $input = json_decode($call->function->arguments, true) ?? [];
                    [$result, $listingIds] = $this->dispatchTool($toolkit, $call->function->name, $input);
                    if ($listingIds !== null) {
                        $lastListingIds = $listingIds;
                    }

                    $messages[] = [
                        'role' => 'tool',
                        'tool_call_id' => $call->id,
                        'content' => is_string($result) ? $result : json_encode($result),
                    ];
                }

                $response = $client->chat()->create(['model' => $model, 'messages' => $messages, 'tools' => $tools]);
                $choice = $response->choices[0];
            }

            $text = $choice->message->content ?? '';

            return new AiDriverReply(reply: trim($text) !== '' ? $text : "I'm not sure how to help with that — could you rephrase?", listingIds: $lastListingIds);
        } catch (ErrorException $e) {
            throw new AiDriverException('OpenAI API error: '.$e->getMessage(), previous: $e);
        } catch (Throwable $e) {
            throw new AiDriverException('OpenAI driver failure: '.$e->getMessage(), previous: $e);
        }
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

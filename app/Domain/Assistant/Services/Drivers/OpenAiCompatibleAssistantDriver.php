<?php

namespace App\Domain\Assistant\Services\Drivers;

use App\Domain\Assistant\Contracts\AiAssistantDriver;
use App\Domain\Assistant\Contracts\AiDriverReply;
use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Domain\Assistant\Services\AssistantToolkit;
use App\Models\AiProviderConfig;
use OpenAI\Client;
use OpenAI\Exceptions\ErrorException;
use Throwable;

/**
 * Shared Chat Completions tool-calling loop for any OpenAI-compatible API.
 * OpenAI itself is one such API, but so are most other hosted and
 * self-hosted "AI agents" an admin might want to add later (Groq,
 * Together, DeepSeek, OpenRouter, a local Ollama instance, ...) — that's
 * exactly what CustomAssistantDriver is for: an admin plugs one in via a
 * base URL, key, and model name, with no new PHP class required as long as
 * it speaks this same request/response shape.
 */
abstract class OpenAiCompatibleAssistantDriver implements AiAssistantDriver
{
    private const MAX_TOOL_ROUNDS = 6;

    abstract protected function client(AiProviderConfig $config): Client;

    abstract protected function model(AiProviderConfig $config): string;

    public function reply(AiProviderConfig $config, string $message, array $history, AssistantToolkit $toolkit): AiDriverReply
    {
        $client = $this->client($config);
        $model = $this->model($config);

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
            throw new AiDriverException(static::label().' API error: '.$e->getMessage(), previous: $e);
        } catch (Throwable $e) {
            throw new AiDriverException(static::label().' driver failure: '.$e->getMessage(), previous: $e);
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

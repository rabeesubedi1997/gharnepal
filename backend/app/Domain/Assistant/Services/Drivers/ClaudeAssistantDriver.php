<?php

namespace App\Domain\Assistant\Services\Drivers;

use Anthropic\Client;
use Anthropic\Core\Exceptions\APIStatusException;
use Anthropic\Messages\ToolUseBlock;
use App\Domain\Assistant\Contracts\AiAssistantDriver;
use App\Domain\Assistant\Contracts\AiDriverReply;
use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Domain\Assistant\Services\AssistantToolkit;
use App\Models\AiProviderConfig;
use Throwable;

/**
 * A real, open-ended conversational backend for the assistant — only used
 * when an admin has configured and enabled a Claude AiProviderConfig (see
 * AiAssistantDriverRegistry). The default remains the free PropertySearchParser;
 * this exists purely as an opt-in upgrade path (see feedback-no-paid-ai-apis
 * in project memory for why it's opt-in, not the default).
 */
class ClaudeAssistantDriver implements AiAssistantDriver
{
    private const MAX_TOOL_ROUNDS = 6;

    public static function providerKey(): string
    {
        return 'claude';
    }

    public static function label(): string
    {
        return 'Claude (Anthropic)';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'api_key', 'label' => 'API Key', 'type' => 'password', 'required' => true],
            ['key' => 'model', 'label' => 'Model (optional — defaults to claude-opus-5)', 'type' => 'text', 'required' => false],
        ];
    }

    public function reply(AiProviderConfig $config, string $message, array $history, AssistantToolkit $toolkit): AiDriverReply
    {
        $apiKey = $config->credential('api_key');
        if (! $apiKey) {
            throw new AiDriverException('Claude is enabled but has no API key configured.');
        }

        $client = new Client(apiKey: $apiKey);
        $model = $config->credential('model') ?: 'claude-opus-5';

        $tools = array_map(fn (array $t) => [
            'name' => $t['name'],
            'description' => $t['description'],
            'inputSchema' => $t['parameters'],
        ], AssistantToolkit::toolDefinitions());

        $messages = [
            ...array_map(fn (array $m) => ['role' => $m['role'], 'content' => $m['content']], $history),
            ['role' => 'user', 'content' => $message],
        ];

        $lastListingIds = [];

        try {
            $response = $client->messages->create(
                model: $model,
                maxTokens: 2000,
                system: [['type' => 'text', 'text' => $this->systemPrompt($toolkit), 'cacheControl' => ['type' => 'ephemeral']]],
                tools: $tools,
                messages: $messages,
            );

            $rounds = 0;
            while ($response->stopReason === 'tool_use' && $rounds < self::MAX_TOOL_ROUNDS) {
                $rounds++;
                $toolResults = [];

                foreach ($response->content as $block) {
                    if (! $block instanceof ToolUseBlock) {
                        continue;
                    }

                    [$result, $listingIds] = $this->dispatchTool($toolkit, $block->name, $block->input);
                    if ($listingIds !== null) {
                        $lastListingIds = $listingIds;
                    }

                    $toolResults[] = [
                        'type' => 'tool_result',
                        'toolUseID' => $block->id,
                        'content' => is_string($result) ? $result : json_encode($result),
                    ];
                }

                $messages[] = ['role' => 'assistant', 'content' => $response->content];
                $messages[] = ['role' => 'user', 'content' => $toolResults];

                $response = $client->messages->create(
                    model: $model,
                    maxTokens: 2000,
                    system: [['type' => 'text', 'text' => $this->systemPrompt($toolkit), 'cacheControl' => ['type' => 'ephemeral']]],
                    tools: $tools,
                    messages: $messages,
                );
            }

            $text = '';
            foreach ($response->content as $block) {
                if ($block->type === 'text') {
                    $text .= $block->text;
                }
            }

            return new AiDriverReply(reply: trim($text) !== '' ? $text : "I'm not sure how to help with that — could you rephrase?", listingIds: $lastListingIds);
        } catch (APIStatusException $e) {
            throw new AiDriverException('Claude API error: '.$e->getMessage(), previous: $e);
        } catch (Throwable $e) {
            throw new AiDriverException('Claude driver failure: '.$e->getMessage(), previous: $e);
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

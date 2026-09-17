<?php

namespace App\Domain\Assistant\Services\Drivers;

use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Models\AiProviderConfig;
use OpenAI\Client;

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
class OpenAiAssistantDriver extends OpenAiCompatibleAssistantDriver
{
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

    protected function client(AiProviderConfig $config): Client
    {
        $apiKey = $config->credential('api_key');
        if (! $apiKey) {
            throw new AiDriverException('OpenAI is enabled but is missing its API key.');
        }

        return \OpenAI::client($apiKey);
    }

    protected function model(AiProviderConfig $config): string
    {
        $model = $config->credential('model');
        if (! $model) {
            throw new AiDriverException('OpenAI is enabled but is missing its model.');
        }

        return $model;
    }
}

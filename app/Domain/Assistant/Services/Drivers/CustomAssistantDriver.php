<?php

namespace App\Domain\Assistant\Services\Drivers;

use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Models\AiProviderConfig;
use OpenAI\Client;

/**
 * Lets an admin plug in "some other AI agent" without anyone writing a new
 * driver class — any vendor whose API speaks the same shape as OpenAI's
 * Chat Completions endpoint (function-calling included) works here: Groq,
 * Together, DeepSeek, OpenRouter, Fireworks, a local Ollama instance with
 * its OpenAI-compatible layer enabled, etc. The admin supplies the base
 * URL, key, and model themselves; this driver never guesses a default for
 * any of them, since there's no single "custom" vendor to default to.
 *
 * Unlike claude/openai/gemini (one config row each, by convention — not
 * enforced anymore), any number of these can be added side by side, e.g.
 * to keep a Groq key and a DeepSeek key both on file and switch between
 * them. Only one AiProviderConfig row total may be enabled at a time
 * regardless of provider — see AiProviderConfigController.
 */
class CustomAssistantDriver extends OpenAiCompatibleAssistantDriver
{
    public static function providerKey(): string
    {
        return 'custom';
    }

    public static function label(): string
    {
        return 'Custom (OpenAI-compatible API)';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'base_url', 'label' => 'API base URL (e.g. https://api.groq.com/openai/v1)', 'type' => 'text', 'required' => true],
            ['key' => 'api_key', 'label' => 'API Key', 'type' => 'password', 'required' => true],
            ['key' => 'model', 'label' => 'Model name', 'type' => 'text', 'required' => true],
        ];
    }

    protected function client(AiProviderConfig $config): Client
    {
        $apiKey = $config->credential('api_key');
        $baseUrl = $config->credential('base_url');
        if (! $apiKey || ! $baseUrl) {
            throw new AiDriverException("This custom AI agent (\"{$config->label}\") is enabled but is missing its API key or base URL.");
        }

        return \OpenAI::factory()
            ->withApiKey($apiKey)
            ->withBaseUri(rtrim($baseUrl, '/'))
            ->make();
    }

    protected function model(AiProviderConfig $config): string
    {
        $model = $config->credential('model');
        if (! $model) {
            throw new AiDriverException("This custom AI agent (\"{$config->label}\") is enabled but is missing its model name.");
        }

        return $model;
    }
}

<?php

namespace App\Domain\Assistant\Services;

use App\Domain\Assistant\Contracts\AiAssistantDriver;
use App\Domain\Assistant\Services\Drivers\ClaudeAssistantDriver;
use App\Domain\Assistant\Services\Drivers\CustomAssistantDriver;
use App\Domain\Assistant\Services\Drivers\GeminiAssistantDriver;
use App\Domain\Assistant\Services\Drivers\OpenAiAssistantDriver;
use InvalidArgumentException;

/**
 * The one place that lists which real-LLM providers exist. Mirrors
 * App\Domain\Payments\Services\PaymentGatewayDriverRegistry — adding a new
 * *named* provider still means writing a driver class and adding one line
 * here, but 'custom' (CustomAssistantDriver) is the escape hatch that needs
 * neither: an admin can add any OpenAI-compatible AI agent from the admin
 * UI alone, and any number of them side by side (see AiProviderConfigController).
 */
class AiAssistantDriverRegistry
{
    /** @var array<string, class-string<AiAssistantDriver>> */
    private const DRIVERS = [
        'claude' => ClaudeAssistantDriver::class,
        'openai' => OpenAiAssistantDriver::class,
        'gemini' => GeminiAssistantDriver::class,
        'custom' => CustomAssistantDriver::class,
    ];

    public static function providerKeys(): array
    {
        return array_keys(self::DRIVERS);
    }

    public static function resolve(string $provider): AiAssistantDriver
    {
        $class = self::DRIVERS[$provider] ?? null;

        if (! $class) {
            throw new InvalidArgumentException("Unknown AI provider: {$provider}");
        }

        return app($class);
    }

    /** @return array<int, array{provider: string, label: string, fields: array}> */
    public static function catalog(): array
    {
        return collect(self::DRIVERS)
            ->map(fn (string $class, string $provider) => [
                'provider' => $provider,
                'label' => $class::label(),
                'fields' => $class::credentialFields(),
            ])
            ->values()
            ->all();
    }
}

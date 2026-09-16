<?php

namespace App\Domain\Assistant\Contracts;

use App\Domain\Assistant\Exceptions\AiDriverException;
use App\Domain\Assistant\Services\AssistantToolkit;
use App\Models\AiProviderConfig;

/**
 * What every real-LLM assistant backend implements. Mirrors
 * App\Domain\Payments\Contracts\PaymentGatewayDriver — a new provider means
 * writing one class implementing this, once; after that any number of admin
 * credential configs for it are pure AiProviderConfig rows, no more code.
 * See AiAssistantDriverRegistry for the provider => class map.
 */
interface AiAssistantDriver
{
    /** Unique provider key this driver handles, e.g. 'claude'. Matches AiProviderConfig::provider. */
    public static function providerKey(): string;

    public static function label(): string;

    /**
     * What the admin form needs to collect for a config using this
     * provider — drives both the admin UI's dynamic form and this driver's
     * own validation of what it's given.
     *
     * @return array<int, array{key: string, label: string, type: 'text'|'password', required: bool}>
     */
    public static function credentialFields(): array;

    /**
     * Hold one turn of a genuinely open-ended conversation, using $toolkit's
     * tools to search real listing data — unlike the rule-based
     * PropertySearchParser path, this has no fixed set of intents.
     *
     * @param  list<array{role:string,content:string}>  $history  prior turns of this conversation, oldest first
     *
     * @throws AiDriverException on any failure — AssistantService catches this and falls back to the rule-based flow
     */
    public function reply(AiProviderConfig $config, string $message, array $history, AssistantToolkit $toolkit): AiDriverReply;
}

<?php

namespace App\Domain\Assistant\Exceptions;

use RuntimeException;

/**
 * Wraps any provider-SDK failure (bad key, rate limit, network, outage) so
 * AssistantService has one exception type to catch and fall back to the
 * free rule-based parser on, regardless of which provider was in use.
 */
class AiDriverException extends RuntimeException {}

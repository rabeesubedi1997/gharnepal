<?php

namespace App\Domain\Assistant\Contracts;

/**
 * One driver turn's result. $listingIds is whichever listings the last
 * successful search_listings tool call actually returned this turn — how
 * AssistantService attaches real PropertyCard data to an LLM-driven reply,
 * the same way it does for the rule-based path.
 */
final class AiDriverReply
{
    /** @param  list<int>  $listingIds */
    public function __construct(
        public readonly string $reply,
        public readonly array $listingIds = [],
    ) {}
}

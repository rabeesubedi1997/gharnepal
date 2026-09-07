<?php

namespace App\Domain\Marketing;

/**
 * Canonical list of ad slots the frontend actually renders. Keep this in
 * sync with `frontend/src/lib/api/advertisements.ts` (`PLACEMENTS`) — that
 * file mirrors these keys/labels for the admin picker, same dual-definition
 * pattern already used for design tokens (index.css <-> tokens.ts).
 *
 * A slot only ever shows something if an active ad targets it — there is no
 * placeholder ad space anywhere.
 */
class AdvertisementPlacement
{
    public const OPTIONS = [
        'home_before_footer' => 'Homepage — above the footer',
        'search_sidebar' => 'Search results — sidebar',
        'listing_detail_sidebar' => 'Listing detail — sidebar',
    ];

    /** @return list<string> */
    public static function keys(): array
    {
        return array_keys(self::OPTIONS);
    }
}

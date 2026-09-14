<?php

namespace App\Domain\Matching\Services;

use App\Models\MatchPreference;
use App\Models\MatchResult;
use App\Models\PropertyListing;
use App\Notifications\MatchThresholdNotification;

/**
 * Match results were previously only ever (re)computed per-user, on
 * preference save or a manual "Refresh" click — a listing published after
 * that point never updated an existing buyer's cached matches, and nothing
 * ever notified a buyer that a strong (80%+) match had appeared. This is the
 * missing piece, mirroring SavedSearchAlertService::notifyInstantMatches()
 * exactly: hooked into PropertyListingService::approve() so it runs the
 * moment a listing goes live.
 *
 * Deliberately does NOT call MatchScorer::recompute() (which deletes and
 * replaces a user's *entire* result set) — this only ever touches the one
 * (user, listing) pair for the listing that just published, so it can't
 * clobber results a full recompute would otherwise keep. A user's cached
 * matches can end up with more than MatchScorer::MAX_RESULTS rows over time
 * as a result; that's an acceptable trade for MVP volume and self-corrects
 * the next time the user saves preferences or hits Refresh.
 */
class SmartMatchAlertService
{
    private const THRESHOLD = 80;

    public function __construct(private readonly MatchScorer $matchScorer) {}

    public function notifyThresholdMatches(PropertyListing $listing): void
    {
        $listing->loadMissing([
            'property.address.municipality',
            'property.address.neighborhood.pois',
            'property.address.neighborhood.score.factors',
            'property.media',
            'trustScore',
        ]);

        MatchPreference::query()
            ->with('user')
            ->chunkById(50, function ($preferences) use ($listing) {
                foreach ($preferences as $preference) {
                    if (! $preference->user) {
                        continue;
                    }

                    if (! $this->matchScorer->listingMatchesHardFilters($listing, $preference)) {
                        continue;
                    }

                    $scored = $this->matchScorer->score($listing, $preference);
                    if ($scored['score'] <= 0) {
                        continue;
                    }

                    $existing = MatchResult::where('user_id', $preference->user_id)
                        ->where('property_listing_id', $listing->id)
                        ->first();
                    $previousScore = $existing?->score;

                    MatchResult::updateOrCreate(
                        ['user_id' => $preference->user_id, 'property_listing_id' => $listing->id],
                        ['score' => $scored['score'], 'reasons' => $scored['reasons'], 'computed_at' => now()],
                    );

                    // Only notify on the crossing itself (previously below
                    // threshold or never scored), not on every recompute —
                    // otherwise a buyer would get re-notified about the same
                    // listing indefinitely.
                    if ($scored['score'] >= self::THRESHOLD && ($previousScore === null || $previousScore < self::THRESHOLD)) {
                        $preference->user->notify(new MatchThresholdNotification($listing, $scored['score']));
                    }
                }
            });
    }
}

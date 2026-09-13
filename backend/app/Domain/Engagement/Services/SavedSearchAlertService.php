<?php

namespace App\Domain\Engagement\Services;

use App\Domain\Properties\Services\ListingFilterQuery;
use App\Models\PropertyListing;
use App\Models\SavedSearch;
use App\Notifications\SavedSearchMatchNotification;
use Illuminate\Support\Carbon;

/**
 * Saved searches (CRUD, `alert_frequency`, `last_notified_at`) already
 * existed end-to-end — the one genuinely missing piece was anything that
 * actually scans for new matches and notifies. This is that piece.
 */
class SavedSearchAlertService
{
    /**
     * Called right after a listing is newly published — the 'instant'
     * cadence. Kept cheap: only saved searches with alert_frequency=instant
     * are even queried, and matching reuses the exact same filter logic the
     * public search endpoint uses (ListingFilterQuery), so an alert can
     * never fire for something the saved search wouldn't actually surface.
     */
    public function notifyInstantMatches(PropertyListing $listing): void
    {
        SavedSearch::query()
            ->where('alert_frequency', 'instant')
            ->with('user')
            ->chunkById(50, function ($searches) use ($listing) {
                foreach ($searches as $search) {
                    if (! $search->user) {
                        continue;
                    }

                    if ($this->listingMatchesFilters($listing, $search->filters ?? [])) {
                        $search->user->notify(new SavedSearchMatchNotification($search, [$listing]));
                        $search->update(['last_notified_at' => now()]);
                    }
                }
            });
    }

    /**
     * Called by the scheduled `saved-searches:send-digests` command for the
     * 'daily'/'weekly' cadences. Returns how many digests were actually sent
     * (a search with zero new matches in its window is skipped, not
     * "notified with nothing").
     */
    public function sendDueDigests(string $frequency): int
    {
        $window = $frequency === 'daily' ? now()->subDay() : now()->subWeek();
        $sent = 0;

        SavedSearch::query()
            ->where('alert_frequency', $frequency)
            ->where(function ($q) use ($window) {
                $q->whereNull('last_notified_at')->orWhere('last_notified_at', '<=', $window);
            })
            ->with('user')
            ->chunkById(50, function ($searches) use (&$sent) {
                foreach ($searches as $search) {
                    if (! $search->user) {
                        continue;
                    }

                    $since = $search->last_notified_at ?? $search->created_at;
                    $matches = $this->matchesSince($search->filters ?? [], $since);

                    if ($matches->isNotEmpty()) {
                        $search->user->notify(new SavedSearchMatchNotification($search, $matches->all()));
                        $sent++;
                    }

                    // Always advance the watermark, matches or not — a quiet
                    // week shouldn't mean a huge backlog dumped the moment
                    // one finally does appear.
                    $search->update(['last_notified_at' => now()]);
                }
            });

        return $sent;
    }

    private function listingMatchesFilters(PropertyListing $listing, array $filters): bool
    {
        $query = PropertyListing::query()->whereKey($listing->id);
        ListingFilterQuery::apply($query, $filters);

        if (! $query->exists()) {
            return false;
        }

        $listing->loadMissing('property.address');

        return ListingFilterQuery::matchesPolygon($filters, $listing->property?->address?->lat, $listing->property?->address?->lng);
    }

    private function matchesSince(array $filters, Carbon $since)
    {
        $query = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->where('published_at', '>=', $since)
            ->with('property.address')
            ->latest('published_at')
            ->limit(20);

        ListingFilterQuery::apply($query, $filters);

        return $query->get()->filter(
            fn (PropertyListing $listing) => ListingFilterQuery::matchesPolygon(
                $filters, $listing->property?->address?->lat, $listing->property?->address?->lng,
            ),
        )->values();
    }
}

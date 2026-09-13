<?php

namespace App\Domain\Agencies\Services;

use App\Models\Agency;
use App\Models\Conversation;
use App\Models\PropertyListing;
use App\Models\SavedSearch;
use App\Models\ViewingRequest;

/**
 * Every figure here is a real query against this agency's own data — no
 * simulated CRM metrics (weekly-digest open rates, an "NRI buyer match
 * index," a WhatsApp-vs-portal inquiry split) that this platform has no
 * way to actually measure. Where the mockup this was built against showed
 * a number nothing here can honestly compute, it's either replaced with a
 * real equivalent or left out — see AgencyDashboardController's docblock.
 */
class AgencyDashboardService
{
    /** @return array<int, int> */
    private function memberIds(Agency $agency): array
    {
        return $agency->members()->pluck('users.id')->all();
    }

    private function activeListingsQuery(Agency $agency)
    {
        $memberIds = $this->memberIds($agency);

        return PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->whereHas('property', fn ($q) => $q->whereIn('owner_user_id', $memberIds)->orWhereIn('created_by', $memberIds));
    }

    public function overview(Agency $agency): array
    {
        $memberIds = $this->memberIds($agency);
        $listings = $this->activeListingsQuery($agency)->with('property.address.municipality')->get();

        $byCity = $listings
            ->groupBy(fn ($l) => $l->property?->address?->municipality?->name ?? 'Unspecified')
            ->map(fn ($group) => $group->count())
            ->sortDesc();

        $newThisWeek = $listings->where('published_at', '>=', now()->subWeek())->count();

        $conversations30d = Conversation::query()
            ->whereIn('owner_user_id', $memberIds)
            ->where('created_at', '>=', now()->subDays(30))
            ->get(['id', 'owner_user_id']);

        $respondedCount = $conversations30d->isEmpty() ? 0 : Conversation::query()
            ->whereIn('id', $conversations30d->pluck('id'))
            ->whereHas('messages', fn ($q) => $q->whereIn('sender_user_id', $memberIds))
            ->count();

        $upcomingVisits = ViewingRequest::query()
            ->whereHas('listing.property', fn ($q) => $q->whereIn('owner_user_id', $memberIds)->orWhereIn('created_by', $memberIds))
            ->whereIn('status', [ViewingRequest::STATUS_REQUESTED, ViewingRequest::STATUS_CONFIRMED])
            ->where(function ($q) {
                $q->where('confirmed_datetime', '>=', now())->orWhere('proposed_datetime', '>=', now());
            })
            ->get();

        $visitsNext7Days = $upcomingVisits->filter(function ($v) {
            $when = $v->confirmed_datetime ?? $v->proposed_datetime;
            return $when && $when->lte(now()->addDays(7));
        });

        $visitsToday = $visitsNext7Days->filter(function ($v) {
            $when = $v->confirmed_datetime ?? $v->proposed_datetime;
            return $when && $when->isToday();
        });

        // Sale-only — a rented listing's monthly price summed alongside a
        // sale listing's total price would be a meaningless mixed figure.
        $saleListings = $listings->where('purpose', 'sale');

        return [
            'portfolio' => [
                'active_count' => $listings->count(),
                'new_this_week' => $newThisWeek,
                'by_city' => $byCity->take(3)->map(fn ($count, $city) => ['city' => $city, 'count' => $count])->values(),
            ],
            'inquiries_30d' => [
                'count' => $conversations30d->count(),
                'response_rate_pct' => $conversations30d->count() > 0
                    ? (int) round($respondedCount / $conversations30d->count() * 100)
                    : null,
            ],
            'site_visits' => [
                'upcoming_7d' => $visitsNext7Days->count(),
                'today' => $visitsToday->count(),
            ],
            'for_sale_portfolio_value' => [
                'total' => (float) $saleListings->sum('price'),
                'listing_count' => $saleListings->count(),
            ],
            'alert_reach' => $this->alertReach($byCity->keys()->all()),
        ];
    }

    /** Real count of active (non-"off") saved-search alert subscriptions
     * whose filter targets a city where this agency currently has an
     * active listing — an honest "who could plausibly see your next
     * listing" figure, deliberately not framed as a delivery/open-rate
     * metric this platform has no tracking for. */
    private function alertReach(array $cityNames): int
    {
        if (empty($cityNames)) {
            return 0;
        }

        $municipalityIds = \App\Models\Municipality::whereIn('name', $cityNames)->pluck('id');

        return SavedSearch::where('alert_frequency', '!=', 'off')
            ->get(['id', 'filters'])
            ->filter(fn ($s) => in_array($s->filters['municipality_id'] ?? null, $municipalityIds->all(), true))
            ->count();
    }

    public function listings(Agency $agency, ?string $category, ?string $search, string $sort): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        $query = $this->activeListingsQuery($agency)
            ->with(['property.address.municipality', 'property.address.ward', 'property.media'])
            ->withCount(['viewingRequests as leads_count'])
            ->withCount(['conversations as inquiries_count']);

        if ($category === 'houses') {
            $query->whereHas('property', fn ($q) => $q->whereIn('property_type', ['house', 'apartment', 'room']));
        } elseif ($category === 'land') {
            $query->whereHas('property', fn ($q) => $q->where('property_type', 'land'));
        } elseif ($category === 'commercial') {
            $query->whereHas('property', fn ($q) => $q->where('property_type', 'commercial'));
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('slug', 'like', "%{$search}%");
            });
        }

        match ($sort) {
            'leads' => $query->orderByDesc('leads_count'),
            'price_high' => $query->orderByDesc('price'),
            'price_low' => $query->orderBy('price'),
            default => $query->latest('published_at'),
        };

        return $query->paginate(10);
    }

    public function inquiries(Agency $agency, int $limit = 10)
    {
        $memberIds = $this->memberIds($agency);

        return Conversation::query()
            ->whereIn('owner_user_id', $memberIds)
            ->with(['buyer', 'listing'])
            ->withCount('messages')
            ->latest('last_message_at')
            ->take($limit)
            ->get();
    }

    public function upcomingSiteVisits(Agency $agency)
    {
        $memberIds = $this->memberIds($agency);

        return ViewingRequest::query()
            ->whereHas('listing.property', fn ($q) => $q->whereIn('owner_user_id', $memberIds)->orWhereIn('created_by', $memberIds))
            ->whereIn('status', [ViewingRequest::STATUS_REQUESTED, ViewingRequest::STATUS_CONFIRMED])
            ->with(['listing.property.address', 'requester'])
            ->get()
            ->filter(function ($v) {
                $when = $v->confirmed_datetime ?? $v->proposed_datetime;
                return $when && $when->between(now(), now()->addDays(7));
            })
            ->sortBy(fn ($v) => $v->confirmed_datetime ?? $v->proposed_datetime)
            ->values();
    }
}

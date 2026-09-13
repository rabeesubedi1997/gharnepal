<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Calculators\Services\AreaUnitConverter;
use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\SavedSearch;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

/**
 * Real, computed numbers for the homepage's trust/transparency strip —
 * deliberately not the kind of thing a redesign mockup tends to show
 * (invented "Rs 120Cr+ transactions facilitated" style figures). Every
 * value here is a genuine count from the database; none of them touch
 * payment amounts, since the sandbox payment gateway moves no real money
 * and a "value transacted" claim built on that would be actively
 * misleading, not just approximate.
 */
class PlatformStatsController extends Controller
{
    public function index(): JsonResponse
    {
        $stats = Cache::remember('platform_stats', now()->addMinutes(15), function () {
            $publishedListings = PropertyListing::where('status', PropertyListing::STATUS_PUBLISHED);

            $publishedCount = (clone $publishedListings)->count();
            // Wrapped in a closure so the OR stays scoped to "owner verified
            // or creator verified" — left unwrapped, Eloquent's orWhereHas
            // would combine with the outer status filter as a top-level OR
            // instead of staying inside this AND condition.
            $phoneVerifiedOwnerCount = (clone $publishedListings)
                ->where(function ($q) {
                    $q->whereHas('property.owner', fn ($q2) => $q2->whereNotNull('phone_verified_at'))
                        ->orWhereHas('property.createdBy', fn ($q2) => $q2->whereNotNull('phone_verified_at'));
                })
                ->count();

            return [
                'published_listings' => $publishedCount,
                'verified_agencies' => Agency::whereNotNull('verified_at')->where('status', 'active')->count(),
                'phone_verified_owner_pct' => $publishedCount > 0
                    ? (int) round($phoneVerifiedOwnerCount / $publishedCount * 100)
                    : 0,
                'cities_covered' => (clone $publishedListings)
                    ->join('properties', 'properties.id', '=', 'property_listings.property_id')
                    ->join('addresses', function ($join) {
                        $join->on('addresses.addressable_id', '=', 'properties.id')
                            ->where('addresses.addressable_type', Property::class);
                    })
                    ->distinct('addresses.municipality_id')
                    ->count('addresses.municipality_id'),
                // Backs the homepage alert-signup banner's subscriber count —
                // every saved search with alerts actually turned on, not a
                // marketing placeholder like "14,200 active subscribers".
                'active_alert_subscriptions' => SavedSearch::where('alert_frequency', '!=', 'off')->count(),
                // A live per-city median, not a fabricated multi-year
                // "index" — this platform has no years of transaction
                // history to trend, so the honest equivalent of the
                // mockup's price-index chart is today's real snapshot.
                'land_price_per_aana_by_city' => $this->landPricePerAanaByCity(),
            ];
        });

        return response()->json(['data' => $stats]);
    }

    /** @return array<int, array{municipality: string, median_price_per_aana: int, listing_count: int}> */
    private function landPricePerAanaByCity(): array
    {
        $rows = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->whereHas('property', fn ($q) => $q->where('property_type', 'land')->whereNotNull('total_area_sqm'))
            ->with('property.address.municipality')
            ->get()
            ->filter(fn ($listing) => $listing->property?->address?->municipality !== null)
            ->groupBy(fn ($listing) => $listing->property->address->municipality->name)
            ->map(function ($listings, $municipality) {
                $pricesPerAana = $listings->map(function ($listing) {
                    $aana = AreaUnitConverter::fromSqm((float) $listing->property->total_area_sqm, 'aana');

                    return $aana > 0 ? $listing->price / $aana : null;
                })->filter()->sort()->values();

                if ($pricesPerAana->isEmpty()) {
                    return null;
                }

                $mid = intdiv($pricesPerAana->count(), 2);
                $median = $pricesPerAana->count() % 2 === 0
                    ? ($pricesPerAana[$mid - 1] + $pricesPerAana[$mid]) / 2
                    : $pricesPerAana[$mid];

                return [
                    'municipality' => $municipality,
                    'median_price_per_aana' => (int) round($median),
                    'listing_count' => $pricesPerAana->count(),
                ];
            })
            ->filter()
            ->sortByDesc('listing_count')
            ->take(5)
            ->values();

        return $rows->all();
    }
}

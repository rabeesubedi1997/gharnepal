<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\AgencyProfileResource;
use App\Http\Resources\AgencyResource;
use App\Models\Agency;
use App\Models\PropertyListing;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Collection;

/**
 * Public agent/agency directory — verified agencies only. A missing feature
 * the platform had the schema for (Agency, agency_user) but never exposed;
 * added so buyers can browse and vet who they're dealing with, matching the
 * "verified agents" pattern common on established Nepal property sites.
 */
class AgencyController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $agencies = Agency::query()
            ->whereNotNull('verified_at')
            ->where('status', 'active')
            ->withCount('members')
            ->with('members')
            ->orderBy('name')
            ->get()
            ->each(fn (Agency $agency) => $agency->active_listings_count = $this->activeListingsQuery($agency->members)->count());

        return AgencyResource::collection($agencies);
    }

    public function show(string $slug): AgencyProfileResource
    {
        $agency = Agency::query()
            ->whereNotNull('verified_at')
            ->where('status', 'active')
            ->where('slug', $slug)
            ->withCount('members')
            ->with('members')
            ->firstOrFail();

        $eagerLoad = [
            'property.address.municipality',
            'property.address.ward',
            'property.address.neighborhood',
            'property.media',
            'trustScore',
        ];

        $listings = $this->activeListingsQuery($agency->members)->with($eagerLoad)->latest('published_at')->get();
        $agency->setRelation('activeListingsResults', $listings);

        // Closed deals shown as a track-record signal, not hidden the way they
        // are from general search — a buyer vetting an agency benefits from
        // seeing "this agency actually closes deals", not just their current stock.
        $closedListings = $this->closedListingsQuery($agency->members)->with($eagerLoad)->latest('published_at')->take(6)->get();
        $agency->setRelation('closedListingsResults', $closedListings);
        $agency->closed_listings_count = $this->closedListingsQuery($agency->members)->count();

        return new AgencyProfileResource($agency);
    }

    /** @param Collection<int, \App\Models\User> $members */
    private function activeListingsQuery(Collection $members): Builder
    {
        $memberIds = $members->pluck('id');

        return PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->whereHas('property', fn ($q) => $q->whereHas('managers', fn ($q2) => $q2->whereIn('users.id', $memberIds)));
    }

    /** @param Collection<int, \App\Models\User> $members */
    private function closedListingsQuery(Collection $members): Builder
    {
        $memberIds = $members->pluck('id');

        return PropertyListing::query()
            ->whereIn('status', [PropertyListing::STATUS_SOLD, PropertyListing::STATUS_RENTED])
            ->whereHas('property', fn ($q) => $q->whereHas('managers', fn ($q2) => $q2->whereIn('users.id', $memberIds)));
    }
}

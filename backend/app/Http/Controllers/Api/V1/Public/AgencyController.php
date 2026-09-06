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

        $listings = $this->activeListingsQuery($agency->members)
            ->with([
                'property.address.municipality',
                'property.address.ward',
                'property.address.neighborhood',
                'property.media',
                'trustScore',
            ])
            ->latest('published_at')
            ->get();

        $agency->setRelation('activeListingsResults', $listings);

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
}

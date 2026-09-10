<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Properties\Services\PropertyListingService;
use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingDetailResource;
use App\Models\PropertyListing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ListingModerationController extends Controller
{
    public function __construct(private readonly PropertyListingService $listings) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $status = $request->string('status', PropertyListing::STATUS_PENDING_REVIEW)->toString();

        $listings = PropertyListing::query()
            ->where('status', $status)
            ->with(['property.address.municipality', 'property.address.ward', 'property.media', 'createdBy'])
            ->oldest('created_at')
            ->paginate(20);

        return PropertyListingDetailResource::collection($listings);
    }

    public function approve(Request $request, PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('moderate', $listing);

        return new PropertyListingDetailResource($this->listings->approve($listing, $request->user()));
    }

    public function reject(Request $request, PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('moderate', $listing);

        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        return new PropertyListingDetailResource($this->listings->reject($listing, $request->user(), $data['reason']));
    }
}

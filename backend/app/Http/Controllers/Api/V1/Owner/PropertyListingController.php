<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Domain\Properties\Services\PropertyListingService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Property\StorePropertyListingRequest;
use App\Http\Requests\Property\UpdatePropertyListingRequest;
use App\Http\Resources\PropertyListingDetailResource;
use App\Models\Property;
use App\Models\PropertyListing;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PropertyListingController extends Controller
{
    public function __construct(private readonly PropertyListingService $listings) {}

    public function store(StorePropertyListingRequest $request, Property $property): \Illuminate\Http\JsonResponse
    {
        $this->authorize('update', $property);

        $listing = $this->listings->createDraft($property, $request->user(), $request->validated());

        return (new PropertyListingDetailResource($listing))->response()->setStatusCode(201);
    }

    public function show(PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('update', $listing);

        return new PropertyListingDetailResource($listing->load(['property.address', 'amenities']));
    }

    public function update(UpdatePropertyListingRequest $request, PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('update', $listing);

        $listing = $this->listings->update($listing, $request->validated(), $request->user());

        return new PropertyListingDetailResource($listing);
    }

    public function transition(Request $request, PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('update', $listing);

        $data = $request->validate([
            'action' => ['required', Rule::in(['submit', 'pause', 'resume', 'mark_rented', 'mark_sold', 'withdraw'])],
        ]);

        $listing = $this->listings->transition($listing, $data['action']);

        return new PropertyListingDetailResource($listing->load(['property.address', 'amenities']));
    }
}

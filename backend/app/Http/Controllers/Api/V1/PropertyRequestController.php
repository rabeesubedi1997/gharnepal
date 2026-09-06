<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyRequestResource;
use App\Models\PropertyRequest;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/**
 * A demand-side board: a buyer/renter posts what they're looking for instead
 * of only reacting to sellers' listings. Open requests are public (an
 * interested owner/agent needs to be able to browse them); the requester's
 * contact details are never exposed directly — an interested party responds
 * through the same Conversation/messaging system listings use.
 */
class PropertyRequestController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'purpose' => ['sometimes', Rule::in(['sale', 'rent'])],
            'property_type' => ['sometimes', Rule::in(['room', 'apartment', 'house', 'land', 'commercial'])],
            'municipality_id' => ['sometimes', 'integer'],
        ]);

        $query = PropertyRequest::query()
            ->where('status', PropertyRequest::STATUS_OPEN)
            ->with(['user', 'municipality'])
            ->latest();

        if ($request->filled('purpose')) {
            $query->where('purpose', $request->string('purpose'));
        }
        if ($request->filled('property_type')) {
            $query->where('property_type', $request->string('property_type'));
        }
        if ($request->filled('municipality_id')) {
            $query->where('municipality_id', $request->integer('municipality_id'));
        }

        return PropertyRequestResource::collection($query->paginate(15));
    }

    public function mine(Request $request): AnonymousResourceCollection
    {
        $requests = PropertyRequest::query()
            ->where('user_id', $request->user()->id)
            ->with('municipality')
            ->latest()
            ->get();

        return PropertyRequestResource::collection($requests);
    }

    public function store(Request $request): PropertyRequestResource
    {
        $data = $request->validate([
            'purpose' => ['required', Rule::in(['sale', 'rent'])],
            'property_type' => ['nullable', Rule::in(['room', 'apartment', 'house', 'land', 'commercial'])],
            'budget_min' => ['nullable', 'integer', 'min:0'],
            'budget_max' => ['nullable', 'integer', 'min:0', 'gte:budget_min'],
            'bedrooms_min' => ['nullable', 'integer', 'min:0', 'max:20'],
            'municipality_id' => ['nullable', 'integer', 'exists:municipalities,id'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $propertyRequest = PropertyRequest::create([
            ...$data,
            'user_id' => $request->user()->id,
            'status' => PropertyRequest::STATUS_OPEN,
        ]);

        return new PropertyRequestResource($propertyRequest->load(['user', 'municipality']));
    }

    public function close(Request $request, PropertyRequest $propertyRequest): PropertyRequestResource
    {
        abort_unless($propertyRequest->user_id === $request->user()->id, 403);

        $propertyRequest->update(['status' => PropertyRequest::STATUS_CLOSED]);

        return new PropertyRequestResource($propertyRequest->load(['user', 'municipality']));
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Domain\Properties\Services\PropertyService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Property\StorePropertyRequest;
use App\Http\Requests\Property\UpdatePropertyRequest;
use App\Http\Resources\PropertyResource;
use App\Models\Property;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PropertyController extends Controller
{
    public function __construct(private readonly PropertyService $properties) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $properties = Property::query()
            ->where(function ($q) use ($request) {
                $q->where('owner_user_id', $request->user()->id)
                    ->orWhere('created_by', $request->user()->id)
                    ->orWhereHas('managers', fn ($m) => $m->where('users.id', $request->user()->id));
            })
            ->with(['address.municipality', 'address.ward', 'media', 'listings'])
            ->latest()
            ->paginate(15);

        return PropertyResource::collection($properties);
    }

    public function store(StorePropertyRequest $request): \Illuminate\Http\JsonResponse
    {
        $property = $this->properties->createForUser($request->user(), $request->validated());

        return (new PropertyResource($property))->response()->setStatusCode(201);
    }

    public function show(Property $property): PropertyResource
    {
        $this->authorize('view', $property);

        return new PropertyResource($property->load(['address.province', 'address.district', 'address.municipality', 'address.ward', 'address.neighborhood', 'media', 'listings', 'landProfile.lalpurjaDocument']));
    }

    public function update(UpdatePropertyRequest $request, Property $property): PropertyResource
    {
        $this->authorize('update', $property);

        $property = $this->properties->update($property, $request->validated());

        return new PropertyResource($property);
    }
}

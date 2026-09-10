<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AmenityResource;
use App\Models\Amenity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

class AmenityController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AmenityResource::collection(Amenity::orderBy('category')->orderBy('name')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'key' => ['required', 'string', 'max:100', 'alpha_dash', 'unique:amenities,key'],
            'name' => ['required', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:100'],
            'icon' => ['nullable', 'string', 'max:100'],
        ]);

        $amenity = Amenity::create($data);

        return (new AmenityResource($amenity))->response()->setStatusCode(201);
    }

    public function update(Request $request, Amenity $amenity): AmenityResource
    {
        $data = $request->validate([
            'key' => ['sometimes', 'string', 'max:100', 'alpha_dash', Rule::unique('amenities', 'key')->ignore($amenity->id)],
            'name' => ['sometimes', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:100'],
            'icon' => ['nullable', 'string', 'max:100'],
        ]);

        $amenity->update($data);

        return new AmenityResource($amenity);
    }

    public function destroy(Amenity $amenity): Response
    {
        $amenity->delete();

        return response()->noContent();
    }
}

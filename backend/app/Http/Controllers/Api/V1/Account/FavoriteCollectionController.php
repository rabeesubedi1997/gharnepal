<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use App\Http\Resources\FavoriteCollectionResource;
use App\Models\FavoriteCollection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class FavoriteCollectionController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $collections = $request->user()->favoriteCollections()
            ->withCount('favorites')
            ->latest()
            ->get();

        return FavoriteCollectionResource::collection($collections);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate(['name' => ['required', 'string', 'max:100']]);

        $collection = $request->user()->favoriteCollections()->create(['name' => $data['name']]);

        return (new FavoriteCollectionResource($collection))->response()->setStatusCode(201);
    }

    public function update(Request $request, FavoriteCollection $collection): FavoriteCollectionResource
    {
        $this->authorize('update', $collection);

        $data = $request->validate(['name' => ['required', 'string', 'max:100']]);
        $collection->update($data);

        return new FavoriteCollectionResource($collection);
    }

    public function destroy(Request $request, FavoriteCollection $collection): JsonResponse
    {
        $this->authorize('delete', $collection);

        // Favorites in the collection aren't deleted — they fall back to
        // "All saved" (favorite_collection_id set null by the FK's
        // nullOnDelete), same as removing a listing from a folder, not
        // un-saving it.
        $collection->delete();

        return response()->json(['data' => ['deleted' => true]]);
    }
}

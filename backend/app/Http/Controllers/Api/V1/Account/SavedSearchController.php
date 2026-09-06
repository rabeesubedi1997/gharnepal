<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use App\Http\Resources\SavedSearchResource;
use App\Models\SavedSearch;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class SavedSearchController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return SavedSearchResource::collection(
            $request->user()->savedSearches()->latest()->get()
        );
    }

    public function store(Request $request): \Illuminate\Http\JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'filters' => ['required', 'array'],
            'alert_frequency' => ['sometimes', Rule::in(['instant', 'daily', 'weekly', 'off'])],
        ]);

        $savedSearch = $request->user()->savedSearches()->create([
            'name' => $data['name'],
            'filters' => $data['filters'],
            'alert_frequency' => $data['alert_frequency'] ?? 'instant',
        ]);

        return (new SavedSearchResource($savedSearch))->response()->setStatusCode(201);
    }

    public function update(Request $request, SavedSearch $savedSearch): SavedSearchResource
    {
        abort_unless($savedSearch->user_id === $request->user()->id, 403);

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'alert_frequency' => ['sometimes', Rule::in(['instant', 'daily', 'weekly', 'off'])],
        ]);

        $savedSearch->update($data);

        return new SavedSearchResource($savedSearch);
    }

    public function destroy(Request $request, SavedSearch $savedSearch): \Illuminate\Http\Response
    {
        abort_unless($savedSearch->user_id === $request->user()->id, 403);

        $savedSearch->delete();

        return response()->noContent();
    }
}

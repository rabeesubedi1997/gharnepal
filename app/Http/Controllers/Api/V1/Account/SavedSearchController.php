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

        // Nothing stopped the same city (or any identical filter set) being
        // submitted over and over — e.g. re-clicking the homepage alert
        // banner — silently stacking duplicate alerts that'd each separately
        // email/push the user about the same listing. Same user + same
        // filters (order-independent — PHP's == on arrays ignores key
        // order) reuses the existing row instead of creating another.
        $existing = $request->user()->savedSearches()->get()->first(fn ($s) => $s->filters == $data['filters']);

        if ($existing) {
            if ($existing->alert_frequency === 'off' && ($data['alert_frequency'] ?? 'instant') !== 'off') {
                $existing->update(['alert_frequency' => $data['alert_frequency']]);
            }

            return (new SavedSearchResource($existing))->response()->setStatusCode(200);
        }

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

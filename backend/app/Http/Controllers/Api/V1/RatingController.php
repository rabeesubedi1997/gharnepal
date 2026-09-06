<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\RatingResource;
use App\Models\PropertyListing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Validation\ValidationException;

class RatingController extends Controller
{
    public function index(PropertyListing $listing): AnonymousResourceCollection
    {
        $ratings = $listing->ratings()
            ->where('status', 'visible')
            ->with('user')
            ->latest()
            ->paginate(10);

        return RatingResource::collection($ratings);
    }

    /** Upsert — one rating per user per listing, editable any time. */
    public function store(Request $request, PropertyListing $listing): RatingResource
    {
        abort_unless($listing->isPubliclyVisible(), 404);

        $listing->loadMissing('property');
        if ($listing->property?->isManagedBy($request->user())) {
            throw ValidationException::withMessages([
                'rating' => 'You cannot rate your own listing.',
            ]);
        }

        $data = $request->validate([
            'score' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:500'],
        ]);

        $rating = $listing->ratings()->updateOrCreate(
            ['user_id' => $request->user()->id],
            ['score' => $data['score'], 'comment' => $data['comment'] ?? null, 'status' => 'visible'],
        );

        return new RatingResource($rating->load('user'));
    }

    public function destroy(Request $request, PropertyListing $listing): Response
    {
        $listing->ratings()->where('user_id', $request->user()->id)->delete();

        return response()->noContent();
    }
}

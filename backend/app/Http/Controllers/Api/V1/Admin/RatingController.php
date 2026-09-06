<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\RatingResource;
use App\Models\Rating;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class RatingController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['sometimes', Rule::in(['visible', 'hidden'])],
        ]);

        $ratings = Rating::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->with(['user', 'rateable'])
            ->latest()
            ->paginate(25);

        return RatingResource::collection($ratings);
    }

    public function hide(Rating $rating): RatingResource
    {
        $rating->update(['status' => 'hidden']);

        return new RatingResource($rating->load(['user', 'rateable']));
    }

    public function unhide(Rating $rating): RatingResource
    {
        $rating->update(['status' => 'visible']);

        return new RatingResource($rating->load(['user', 'rateable']));
    }
}

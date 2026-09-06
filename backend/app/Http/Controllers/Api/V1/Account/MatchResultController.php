<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Domain\Matching\Services\MatchScorer;
use App\Http\Controllers\Controller;
use App\Http\Resources\MatchResultResource;
use App\Models\MatchResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\ValidationException;

class MatchResultController extends Controller
{
    private const WITH = [
        'propertyListing.property.address.municipality',
        'propertyListing.property.address.ward',
        'propertyListing.property.address.neighborhood',
        'propertyListing.property.media',
        'propertyListing.trustScore',
    ];

    public function __construct(private readonly MatchScorer $matchScorer) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $results = MatchResult::query()
            ->where('user_id', $request->user()->id)
            ->with(self::WITH)
            ->orderByDesc('score')
            ->get();

        return MatchResultResource::collection($results);
    }

    public function refresh(Request $request): AnonymousResourceCollection
    {
        $preference = $request->user()->matchPreference;

        if (! $preference) {
            throw ValidationException::withMessages([
                'preferences' => 'Save your match preferences first, then refresh your matches.',
            ]);
        }

        $this->matchScorer->recompute($preference);

        $results = MatchResult::query()
            ->where('user_id', $request->user()->id)
            ->with(self::WITH)
            ->orderByDesc('score')
            ->get();

        return MatchResultResource::collection($results);
    }
}

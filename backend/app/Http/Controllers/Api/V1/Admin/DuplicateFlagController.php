<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Http\Controllers\Controller;
use App\Http\Resources\DuplicateListingFlagResource;
use App\Models\DuplicateListingFlag;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class DuplicateFlagController extends Controller
{
    public function __construct(private readonly TrustScoreCalculator $trustScoreCalculator) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $status = $request->string('status', 'unreviewed')->toString();

        $flags = DuplicateListingFlag::query()
            ->where('status', $status)
            ->with(['listing', 'duplicateOf'])
            ->latest()
            ->paginate(20);

        return DuplicateListingFlagResource::collection($flags);
    }

    public function confirm(Request $request, DuplicateListingFlag $duplicateFlag): DuplicateListingFlagResource
    {
        $duplicateFlag->update(['status' => 'confirmed', 'reviewed_by' => $request->user()->id]);
        $this->trustScoreCalculator->recompute($duplicateFlag->listing);

        return new DuplicateListingFlagResource($duplicateFlag->load(['listing', 'duplicateOf']));
    }

    public function dismiss(Request $request, DuplicateListingFlag $duplicateFlag): DuplicateListingFlagResource
    {
        $duplicateFlag->update(['status' => 'dismissed', 'reviewed_by' => $request->user()->id]);
        $this->trustScoreCalculator->recompute($duplicateFlag->listing);

        return new DuplicateListingFlagResource($duplicateFlag->load(['listing', 'duplicateOf']));
    }
}

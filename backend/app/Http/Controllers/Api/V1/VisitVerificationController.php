<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Http\Controllers\Controller;
use App\Http\Resources\ViewingRequestResource;
use App\Models\ViewingRequest;
use App\Models\VisitVerification;
use Illuminate\Http\Request;

class VisitVerificationController extends Controller
{
    public function __construct(private readonly TrustScoreCalculator $trustScoreCalculator) {}

    public function store(Request $request, ViewingRequest $viewingRequest): ViewingRequestResource
    {
        $this->authorize('verify', $viewingRequest);

        $data = $request->validate([
            'visited' => ['required', 'boolean'],
            'matched_listing' => ['nullable', 'boolean'],
            'price_accurate' => ['nullable', 'boolean'],
            'host_attended' => ['nullable', 'boolean'],
            'documents_shown' => ['nullable', 'boolean'],
            'overall_comment' => ['nullable', 'string', 'max:1000'],
        ]);

        VisitVerification::updateOrCreate(
            ['viewing_request_id' => $viewingRequest->id],
            [...$data, 'submitted_by' => $request->user()->id, 'submitted_at' => now()],
        );

        $this->trustScoreCalculator->recompute($viewingRequest->listing);

        return new ViewingRequestResource($viewingRequest->load(['listing', 'requester', 'host', 'visitVerification']));
    }
}

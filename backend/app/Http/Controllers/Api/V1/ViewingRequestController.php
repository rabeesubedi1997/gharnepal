<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Engagement\Services\ViewingRequestService;
use App\Http\Controllers\Controller;
use App\Http\Resources\ViewingRequestResource;
use App\Models\PropertyListing;
use App\Models\ViewingRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class ViewingRequestController extends Controller
{
    public function __construct(private readonly ViewingRequestService $viewings) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();
        $as = $request->string('as', 'requester')->toString(); // 'requester' or 'host'

        $viewings = ViewingRequest::query()
            ->where($as === 'host' ? 'host_user_id' : 'requester_user_id', $user->id)
            ->with(['listing', 'requester', 'host', 'visitVerification'])
            ->orderByDesc('proposed_datetime')
            ->paginate(20);

        return ViewingRequestResource::collection($viewings);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'listing_id' => ['required', 'integer', 'exists:property_listings,id'],
            'proposed_datetime' => ['required', 'date', 'after:now'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $listing = PropertyListing::findOrFail($data['listing_id']);
        $viewing = $this->viewings->request($listing, $request->user(), $data['proposed_datetime'], $data['notes'] ?? null);

        return (new ViewingRequestResource($viewing->load(['listing', 'requester', 'host'])))->response()->setStatusCode(201);
    }

    public function transition(Request $request, ViewingRequest $viewingRequest): ViewingRequestResource
    {
        $this->authorize('update', $viewingRequest);

        $data = $request->validate([
            'action' => ['required', Rule::in(['confirm', 'reschedule', 'cancel', 'complete'])],
            'datetime' => ['required_if:action,reschedule', 'nullable', 'date'],
        ]);

        $viewing = match ($data['action']) {
            'confirm' => $this->viewings->confirm($viewingRequest, $request->user()),
            'reschedule' => $this->viewings->reschedule($viewingRequest, $request->user(), $data['datetime']),
            'cancel' => $this->viewings->cancel($viewingRequest, $request->user()),
            'complete' => $this->viewings->complete($viewingRequest, $request->user()),
        };

        return new ViewingRequestResource($viewing->load(['listing', 'requester', 'host']));
    }
}

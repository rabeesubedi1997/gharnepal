<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserVerificationResource;
use App\Models\PropertyListing;
use App\Models\UserVerification;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class VerificationModerationController extends Controller
{
    public function __construct(private readonly TrustScoreCalculator $trustScoreCalculator) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $status = $request->string('status', 'pending')->toString();

        $verifications = UserVerification::query()
            ->where('status', $status)
            ->with(['user', 'document'])
            ->latest()
            ->paginate(20);

        return UserVerificationResource::collection($verifications);
    }

    public function approve(Request $request, UserVerification $verification): UserVerificationResource
    {
        $verification->update([
            'status' => 'approved',
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'rejection_reason' => null,
        ]);

        $this->recomputeOwnerListings($verification->user_id);

        return new UserVerificationResource($verification->load(['user', 'document']));
    }

    public function reject(Request $request, UserVerification $verification): UserVerificationResource
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        $verification->update([
            'status' => 'rejected',
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'rejection_reason' => $data['reason'],
        ]);

        return new UserVerificationResource($verification->load(['user', 'document']));
    }

    /** Identity/agent verification affects every published listing this user owns. */
    private function recomputeOwnerListings(int $userId): void
    {
        PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->whereHas('property', fn ($q) => $q->where('owner_user_id', $userId))
            ->get()
            ->each(fn (PropertyListing $listing) => $this->trustScoreCalculator->recompute($listing));
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Properties\Services\PropertyListingService;
use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingDetailResource;
use App\Models\PropertyListing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class ListingModerationController extends Controller
{
    public function __construct(private readonly PropertyListingService $listings) {}

    /** @var list<string> every real listing status, plus 'all' meaning "no status filter" */
    private const STATUSES = [
        'all', PropertyListing::STATUS_DRAFT, PropertyListing::STATUS_PENDING_REVIEW,
        PropertyListing::STATUS_PUBLISHED, PropertyListing::STATUS_PAUSED,
        PropertyListing::STATUS_RENTED, PropertyListing::STATUS_SOLD,
        PropertyListing::STATUS_REJECTED, PropertyListing::STATUS_EXPIRED,
    ];

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['sometimes', Rule::in(self::STATUSES)],
            'featured' => ['sometimes', 'boolean'],
        ]);

        $status = $request->string('status', PropertyListing::STATUS_PENDING_REVIEW)->toString();
        $featuredOnly = $request->boolean('featured');

        $listings = PropertyListing::query()
            ->when($status !== 'all', fn ($q) => $q->where('status', $status))
            ->when($featuredOnly, fn ($q) => $q->where('featured_until', '>', now()))
            ->with(['property.address.municipality', 'property.address.ward', 'property.media', 'createdBy'])
            // FIFO for the moderation queue (oldest submission reviewed
            // first); anything else is a general browse, so newest-first
            // reads more naturally there.
            ->when(
                $status === PropertyListing::STATUS_PENDING_REVIEW,
                fn ($q) => $q->oldest('created_at'),
                fn ($q) => $q->latest('created_at'),
            )
            ->paginate(20);

        return PropertyListingDetailResource::collection($listings);
    }

    public function approve(Request $request, PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('moderate', $listing);

        return new PropertyListingDetailResource($this->listings->approve($listing, $request->user()));
    }

    public function reject(Request $request, PropertyListing $listing): PropertyListingDetailResource
    {
        $this->authorize('moderate', $listing);

        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        return new PropertyListingDetailResource($this->listings->reject($listing, $request->user(), $data['reason']));
    }
}

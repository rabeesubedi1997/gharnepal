<?php

namespace App\Domain\Properties\Services;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class PropertyListingService
{
    public function __construct(
        private readonly DuplicateListingDetector $duplicateDetector,
        private readonly TrustScoreCalculator $trustScoreCalculator,
    ) {}

    /** Transitions an owner/agent can trigger themselves, without admin involvement. */
    private const OWNER_TRANSITIONS = [
        'submit' => ['from' => [PropertyListing::STATUS_DRAFT], 'to' => PropertyListing::STATUS_PENDING_REVIEW],
        'pause' => ['from' => [PropertyListing::STATUS_PUBLISHED], 'to' => PropertyListing::STATUS_PAUSED],
        'resume' => ['from' => [PropertyListing::STATUS_PAUSED], 'to' => PropertyListing::STATUS_PUBLISHED],
        'mark_rented' => ['from' => [PropertyListing::STATUS_PUBLISHED, PropertyListing::STATUS_PAUSED], 'to' => PropertyListing::STATUS_RENTED],
        'mark_sold' => ['from' => [PropertyListing::STATUS_PUBLISHED, PropertyListing::STATUS_PAUSED], 'to' => PropertyListing::STATUS_SOLD],
        'withdraw' => ['from' => [PropertyListing::STATUS_DRAFT, PropertyListing::STATUS_PENDING_REVIEW], 'to' => PropertyListing::STATUS_DRAFT],
    ];

    public function createDraft(Property $property, User $user, array $data): PropertyListing
    {
        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => $data['purpose'],
            'price' => $data['price'],
            'price_period' => $data['price_period'] ?? null,
            'negotiable' => $data['negotiable'] ?? false,
            'availability_date' => $data['availability_date'] ?? null,
            'title' => $data['title'],
            'slug' => $this->uniqueSlug($data['title']),
            'description' => $data['description'] ?? null,
            'status' => PropertyListing::STATUS_DRAFT,
            'created_by' => $user->id,
        ]);

        if (! empty($data['amenity_ids'])) {
            $listing->amenities()->sync($data['amenity_ids']);
        }

        $listing->priceHistory()->create([
            'price' => $data['price'],
            'changed_by' => $user->id,
            'changed_at' => now(),
        ]);

        return $listing->fresh(['property.address', 'amenities']);
    }

    public function update(PropertyListing $listing, array $data, ?User $user = null): PropertyListing
    {
        $priceChanged = isset($data['price']) && bccomp((string) $data['price'], (string) $listing->price, 2) !== 0;

        $listing->update(array_filter([
            'price' => $data['price'] ?? null,
            'price_period' => $data['price_period'] ?? null,
            'negotiable' => $data['negotiable'] ?? null,
            'availability_date' => $data['availability_date'] ?? null,
            'title' => $data['title'] ?? null,
            'description' => $data['description'] ?? null,
        ], fn ($v) => $v !== null));

        if (isset($data['amenity_ids'])) {
            $listing->amenities()->sync($data['amenity_ids']);
        }

        if ($priceChanged) {
            $listing->priceHistory()->create([
                'price' => $data['price'],
                'changed_by' => $user?->id,
                'changed_at' => now(),
            ]);
        }

        return $listing->fresh(['property.address', 'amenities']);
    }

    public function transition(PropertyListing $listing, string $action): PropertyListing
    {
        if (! isset(self::OWNER_TRANSITIONS[$action])) {
            throw ValidationException::withMessages(['action' => "Unknown action [{$action}]."]);
        }

        $rule = self::OWNER_TRANSITIONS[$action];

        if (! in_array($listing->status, $rule['from'], true)) {
            throw ValidationException::withMessages([
                'action' => "Cannot {$action} a listing with status [{$listing->status}].",
            ]);
        }

        $listing->status = $rule['to'];

        if ($action === 'submit') {
            // Reset any prior admin decision so the moderation queue sees it fresh.
            $listing->reviewed_by = null;
            $listing->reviewed_at = null;
            $listing->rejection_reason = null;
        }

        $listing->save();

        if ($action === 'submit') {
            // Run synchronously in dev (no queue worker guaranteed running); in
            // production this would dispatch a queued job instead so it never
            // blocks the submit request (see plan: DetectDuplicateListingsJob).
            $this->duplicateDetector->scan($listing->fresh(['property.address']));
        }

        return $listing->fresh();
    }

    public function approve(PropertyListing $listing, User $admin): PropertyListing
    {
        if ($listing->status !== PropertyListing::STATUS_PENDING_REVIEW) {
            throw ValidationException::withMessages(['status' => 'Only listings pending review can be approved.']);
        }

        $listing->update([
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
            'rejection_reason' => null,
        ]);

        $listing = $listing->fresh(['property.owner']);
        $listing->property?->owner?->notify(new \App\Notifications\ListingApprovedNotification($listing));
        $this->trustScoreCalculator->recompute($listing);

        return $listing;
    }

    public function reject(PropertyListing $listing, User $admin, string $reason): PropertyListing
    {
        if ($listing->status !== PropertyListing::STATUS_PENDING_REVIEW) {
            throw ValidationException::withMessages(['status' => 'Only listings pending review can be rejected.']);
        }

        $listing->update([
            'status' => PropertyListing::STATUS_REJECTED,
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
            'rejection_reason' => $reason,
        ]);

        $listing = $listing->fresh(['property.owner']);
        $listing->property?->owner?->notify(new \App\Notifications\ListingRejectedNotification($listing, $reason));

        return $listing;
    }

    private function uniqueSlug(string $title): string
    {
        $base = Str::slug($title) ?: 'listing';

        do {
            $slug = $base . '-' . Str::lower(Str::random(5));
        } while (PropertyListing::withTrashed()->where('slug', $slug)->exists());

        return $slug;
    }
}

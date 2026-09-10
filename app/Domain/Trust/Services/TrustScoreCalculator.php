<?php

namespace App\Domain\Trust\Services;

use App\Models\ListingTrustScore;
use App\Models\PropertyListing;
use App\Models\TrustScoreFactor;
use Illuminate\Support\Facades\DB;

/**
 * Pure-ish scoring service: given a listing, produces a persisted per-factor
 * breakdown (never just a black-box number) so the UI's "why this score"
 * popover always reflects exactly what was computed — see plan risk: keep
 * this human-in-the-loop-overridable, never treat it as unforgeable proof.
 */
class TrustScoreCalculator
{
    public function recompute(PropertyListing $listing): ListingTrustScore
    {
        $listing->loadMissing(['property.owner.verifications', 'property.owner.agencies', 'property.address', 'reports', 'duplicateFlags', 'conversations.messages', 'viewingRequests.visitVerification', 'activeOverride']);

        $factors = TrustScoreFactor::where('is_active', true)->get()->keyBy('key');
        $rows = [];
        $computedScore = 0;

        foreach ($factors as $key => $factor) {
            [$points, $explanation] = $this->evaluate($key, $factor->max_points, $listing);
            $computedScore += $points;
            $rows[] = [
                'trust_score_factor_id' => $factor->id,
                'points_awarded' => $points,
                'max_points' => $factor->max_points,
                'explanation' => $explanation,
            ];
        }

        $override = $listing->activeOverride;
        $totalScore = $override?->override_score ?? $computedScore;

        return DB::transaction(function () use ($listing, $computedScore, $totalScore, $rows) {
            $score = ListingTrustScore::updateOrCreate(
                ['property_listing_id' => $listing->id],
                ['computed_score' => $computedScore, 'total_score' => $totalScore, 'computed_at' => now()],
            );

            $score->breakdowns()->delete();
            foreach ($rows as $row) {
                $score->breakdowns()->create($row);
            }

            return $score->load('breakdowns.factor');
        });
    }

    /** @return array{0: int, 1: string} */
    private function evaluate(string $key, int $maxPoints, PropertyListing $listing): array
    {
        $owner = $listing->property?->owner;

        return match ($key) {
            TrustScoreFactor::PHONE_VERIFIED => $owner?->phone_verified_at
                ? [$maxPoints, 'Owner phone verified on ' . $owner->phone_verified_at->toFormattedDateString() . '.']
                : [0, "Owner hasn't verified their phone number yet."],

            TrustScoreFactor::IDENTITY_VERIFIED => $owner?->isVerified()
                ? [$maxPoints, "Owner's identity document has been reviewed and approved."]
                : [0, 'No approved identity verification on file for the owner.'],

            TrustScoreFactor::AGENT_VERIFIED => $this->isAgentVerified($owner)
                ? [$maxPoints, 'Poster is a verified agent or belongs to a verified agency.']
                : [0, 'Poster has no verified agent/agency credential.'],

            TrustScoreFactor::LOCATION_CONFIRMED => ($listing->property?->address?->lat && $listing->property?->address?->lng)
                ? [$maxPoints, 'Property has a confirmed map pin location.']
                : [0, 'No precise map location set for this property yet.'],

            TrustScoreFactor::LISTING_AGE => $this->listingAgeScore($listing, $maxPoints),

            TrustScoreFactor::NO_DUPLICATE_FLAGS => $listing->duplicateFlags->where('status', 'confirmed')->isEmpty()
                ? [$maxPoints, 'No confirmed duplicate-listing flags.']
                : [0, 'This listing has a confirmed duplicate flag.'],

            TrustScoreFactor::NO_UNRESOLVED_REPORTS => $listing->reports->whereIn('status', ['open', 'action_taken'])->isEmpty()
                ? [$maxPoints, 'No open or actioned user reports.']
                : [0, 'This listing has an open or actioned user report.'],

            TrustScoreFactor::RESPONSE_RELIABILITY => $this->responseReliabilityScore($listing, $maxPoints),

            TrustScoreFactor::VISIT_VERIFICATION_POSITIVE => $this->visitVerificationScore($listing, $maxPoints),

            default => [0, 'Not yet evaluated.'],
        };
    }

    private function isAgentVerified($owner): bool
    {
        if (! $owner) {
            return false;
        }

        if ($owner->verifications->where('type', 'agent_license')->where('status', 'approved')->isNotEmpty()) {
            return true;
        }

        return $owner->agencies->contains(fn ($agency) => $agency->isVerified());
    }

    /** @return array{0: int, 1: string} */
    private function listingAgeScore(PropertyListing $listing, int $maxPoints): array
    {
        if (! $listing->published_at) {
            return [0, 'Listing is not published yet.'];
        }

        $days = (int) floor($listing->published_at->diffInDays(now()));
        $points = (int) min($maxPoints, floor($days / 30 * $maxPoints));

        return [$points, "Published {$days} day(s) ago."];
    }

    /** @return array{0: int, 1: string} */
    private function responseReliabilityScore(PropertyListing $listing, int $maxPoints): array
    {
        $conversations = $listing->conversations;
        if ($conversations->isEmpty()) {
            return [(int) round($maxPoints / 2), 'No inquiries yet to judge responsiveness — starting neutral.'];
        }

        $ownerId = $listing->property?->owner_user_id;
        $replied = $conversations->filter(fn ($c) => $c->messages->where('sender_user_id', $ownerId)->isNotEmpty())->count();
        $ratio = $replied / $conversations->count();

        return [(int) round($ratio * $maxPoints), "Replied to {$replied} of {$conversations->count()} inquiry thread(s)."];
    }

    /** @return array{0: int, 1: string} */
    private function visitVerificationScore(PropertyListing $listing, int $maxPoints): array
    {
        $positive = $listing->viewingRequests
            ->pluck('visitVerification')
            ->filter()
            ->first(fn ($v) => $v->visited && $v->matched_listing && $v->price_accurate);

        return $positive
            ? [$maxPoints, 'A verified visitor confirmed the listing matched and the price was accurate.']
            : [0, 'No positive visit verification on file yet.'];
    }
}

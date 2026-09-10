<?php

namespace Database\Seeders;

use App\Models\PropertyListing;
use App\Models\Rating;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * A handful of real ratings on real seeded listings so the ratings UI is
 * never shown empty. Depends on DemoDataSeeder's listings/users already
 * existing. Safe to re-run: clears and recreates its own rows only.
 */
class RatingDemoDataSeeder extends Seeder
{
    private const COMMENTS = [
        'Great experience, the owner was very responsive.',
        'Property matched the photos exactly. Highly recommend.',
        'Good location but a bit noisy at night.',
        null,
        'Smooth process from viewing to move-in.',
        'Decent value for the price.',
        null,
        'Would rate higher but water supply was inconsistent.',
    ];

    private const SCORES = [3, 4, 4, 5, 5, 5, 4, 3];

    public function run(): void
    {
        // Deterministic ordering (not inRandomOrder) so re-running this
        // seeder always targets the same listings/raters instead of
        // accumulating new rating rows on every run.
        $listings = PropertyListing::where('status', PropertyListing::STATUS_PUBLISHED)
            ->orderBy('id')
            ->take(8)
            ->get();

        $raters = User::where('email', 'like', '%@demo.gharnepal.test')
            ->orWhere('email', 'buyer@example.com')
            ->orderBy('id')
            ->get();

        if ($raters->isEmpty() || $listings->isEmpty()) {
            return;
        }

        $i = 0;
        foreach ($listings as $listing) {
            $ownerId = $listing->property?->owner_user_id;
            $eligible = $raters->filter(fn ($u) => $u->id !== $ownerId)->values();
            if ($eligible->isEmpty()) {
                continue;
            }

            $rater = $eligible[$i % $eligible->count()];

            Rating::query()->updateOrCreate(
                ['user_id' => $rater->id, 'rateable_type' => PropertyListing::class, 'rateable_id' => $listing->id],
                ['score' => self::SCORES[$i % count(self::SCORES)], 'comment' => self::COMMENTS[$i % count(self::COMMENTS)], 'status' => 'visible'],
            );
            $i++;
        }
    }
}

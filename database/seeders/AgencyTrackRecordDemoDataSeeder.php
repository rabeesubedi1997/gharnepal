<?php

namespace Database\Seeders;

use App\Models\Agency;
use App\Models\PropertyListing;
use Illuminate\Database\Seeder;

/**
 * Marks a couple of each verified agency's own listings as sold/rented so the
 * agency profile's "Track record" section (see AgencyController::show) has
 * something to show on a fresh seed rather than being permanently empty.
 *
 * Idempotent by an explicit guard, not just "select from published" — an
 * agency with more than 2 published listings would otherwise have 2 more
 * converted on every re-run (the earlier, wrong assumption: that a second run
 * would simply find nothing left in `published` status for that agency).
 * Skipping any agency that already has at least one sold/rented listing
 * makes this a true no-op after the first run.
 */
class AgencyTrackRecordDemoDataSeeder extends Seeder
{
    public function run(): void
    {
        Agency::query()->whereNotNull('verified_at')->get()->each(function (Agency $agency) {
            $memberIds = $agency->members()->pluck('users.id');

            $alreadyHasTrackRecord = PropertyListing::query()
                ->whereIn('status', [PropertyListing::STATUS_SOLD, PropertyListing::STATUS_RENTED])
                ->whereHas('property', fn ($q) => $q->whereHas('managers', fn ($q2) => $q2->whereIn('users.id', $memberIds)))
                ->exists();

            if ($alreadyHasTrackRecord) {
                return;
            }

            $listings = PropertyListing::query()
                ->where('status', PropertyListing::STATUS_PUBLISHED)
                ->whereHas('property', fn ($q) => $q->whereHas('managers', fn ($q2) => $q2->whereIn('users.id', $memberIds)))
                ->orderBy('id')
                ->take(2)
                ->get();

            if ($listings->count() < 2) {
                return;
            }

            $listings[0]->update(['status' => PropertyListing::STATUS_SOLD]);
            $listings[1]->update(['status' => PropertyListing::STATUS_RENTED]);
        });
    }
}

<?php

namespace App\Console\Commands;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Models\PropertyListing;
use Illuminate\Console\Command;

class RecomputeTrustScores extends Command
{
    protected $signature = 'trust:recompute-all';

    protected $description = 'Recompute the trust score for every published listing (e.g. after changing factor weights, or backfilling listings published before Trust Index existed).';

    public function handle(TrustScoreCalculator $calculator): int
    {
        $listings = PropertyListing::where('status', PropertyListing::STATUS_PUBLISHED)->get();

        $this->withProgressBar($listings, fn (PropertyListing $listing) => $calculator->recompute($listing));
        $this->newLine(2);
        $this->info("Recomputed trust scores for {$listings->count()} published listing(s).");

        return self::SUCCESS;
    }
}

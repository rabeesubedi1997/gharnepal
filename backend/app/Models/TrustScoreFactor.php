<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrustScoreFactor extends Model
{
    // Keys the TrustScoreCalculator knows how to compute. Kept as constants so
    // the calculator and the seeder never drift out of sync on spelling.
    public const PHONE_VERIFIED = 'phone_verified';
    public const IDENTITY_VERIFIED = 'identity_verified';
    public const AGENT_VERIFIED = 'agent_verified';
    public const LOCATION_CONFIRMED = 'location_confirmed';
    public const LISTING_AGE = 'listing_age';
    public const NO_DUPLICATE_FLAGS = 'no_duplicate_flags';
    public const NO_UNRESOLVED_REPORTS = 'no_unresolved_reports';
    public const RESPONSE_RELIABILITY = 'response_reliability';
    public const VISIT_VERIFICATION_POSITIVE = 'visit_verification_positive';

    protected $fillable = ['key', 'label', 'description', 'max_points', 'is_active'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }
}

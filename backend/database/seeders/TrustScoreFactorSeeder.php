<?php

namespace Database\Seeders;

use App\Models\TrustScoreFactor;
use Illuminate\Database\Seeder;

class TrustScoreFactorSeeder extends Seeder
{
    public function run(): void
    {
        $factors = [
            [
                'key' => TrustScoreFactor::PHONE_VERIFIED, 'label' => 'Phone verified', 'max_points' => 15,
                'description' => "The owner's phone number has been confirmed with an OTP code.",
            ],
            [
                'key' => TrustScoreFactor::IDENTITY_VERIFIED, 'label' => 'Identity verified', 'max_points' => 20,
                'description' => "The owner's identity document has been reviewed and approved by our team.",
            ],
            [
                'key' => TrustScoreFactor::AGENT_VERIFIED, 'label' => 'Agent/agency verified', 'max_points' => 10,
                'description' => 'The poster is a verified agent or belongs to a verified agency.',
            ],
            [
                'key' => TrustScoreFactor::LOCATION_CONFIRMED, 'label' => 'Location confirmed', 'max_points' => 10,
                'description' => 'The property has a confirmed map location, not just a text address.',
            ],
            [
                'key' => TrustScoreFactor::LISTING_AGE, 'label' => 'Listing track record', 'max_points' => 10,
                'description' => 'The listing has been live for a while without being pulled down or flagged.',
            ],
            [
                'key' => TrustScoreFactor::NO_DUPLICATE_FLAGS, 'label' => 'No duplicate flags', 'max_points' => 10,
                'description' => 'This listing has not been confirmed as a duplicate of another listing.',
            ],
            [
                'key' => TrustScoreFactor::NO_UNRESOLVED_REPORTS, 'label' => 'No unresolved reports', 'max_points' => 10,
                'description' => 'No user reports against this listing are open or have led to action.',
            ],
            [
                'key' => TrustScoreFactor::RESPONSE_RELIABILITY, 'label' => 'Responds to inquiries', 'max_points' => 10,
                'description' => 'The owner has a track record of replying to buyer messages.',
            ],
            [
                'key' => TrustScoreFactor::VISIT_VERIFICATION_POSITIVE, 'label' => 'Positive visit feedback', 'max_points' => 5,
                'description' => 'Buyers who visited confirmed the property matched the listing.',
            ],
        ];

        foreach ($factors as $factor) {
            TrustScoreFactor::query()->updateOrCreate(['key' => $factor['key']], $factor);
        }
    }
}

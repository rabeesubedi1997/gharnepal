<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            NepalLocationSeeder::class,
            AmenitySeeder::class,
            TrustScoreFactorSeeder::class,
        ]);

        $admin = User::query()->updateOrCreate(
            ['email' => 'superadmin@gharnepal.local'],
            [
                'name' => 'Super Admin',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );
        $admin->roles()->syncWithoutDetaching(Role::where('key', Role::ADMIN)->pluck('id'));

        $buyer = User::factory()->create([
            'name' => 'Test Buyer',
            'email' => 'buyer@example.com',
        ]);
        $buyer->roles()->syncWithoutDetaching(Role::where('key', Role::BUYER)->pluck('id'));

        // Depends on the admin account existing (attributes POIs to it) and on
        // NepalLocationSeeder's neighborhoods already being present.
        $this->call(NeighborhoodDemoDataSeeder::class);

        // Depends on locations/amenities/roles above. Populates the
        // marketplace with realistic listings, owners, and agencies so the
        // UI is never shown near-empty.
        $this->call(DemoDataSeeder::class);

        // Homepage slider demo content — reuses DemoDataSeeder's downloaded photos.
        $this->call(BannerDemoDataSeeder::class);

        // A handful of ratings on DemoDataSeeder's listings, so the ratings UI isn't empty.
        $this->call(RatingDemoDataSeeder::class);

        // Marks a couple of each verified agency's own listings sold/rented so
        // their "Track record" section isn't permanently empty on a fresh seed.
        $this->call(AgencyTrackRecordDemoDataSeeder::class);
    }
}

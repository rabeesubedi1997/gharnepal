<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use RuntimeException;

/**
 * Real reference data only, for a fresh production database — no
 * demo/fake listings, owners, ratings, or agencies (that's DemoDataSeeder
 * and friends, deliberately not called here). Seeds:
 *  - Roles, Nepal's real province/district/municipality/ward hierarchy,
 *    amenity types, and trust-score factors — all things the app can't
 *    function without.
 *  - One real admin account, from PRODUCTION_ADMIN_EMAIL/PASSWORD env
 *    vars (not hardcoded — this lands in a real, internet-facing database).
 *
 * Usage: set PRODUCTION_ADMIN_EMAIL/PRODUCTION_ADMIN_PASSWORD in .env,
 * then `php artisan db:seed --class=Database\\Seeders\\ProductionSeeder`.
 * On a host with no terminal access, run this locally against a throwaway
 * database instead and import the resulting `mysqldump` via phpMyAdmin —
 * see the deployment notes for the exact steps.
 */
class ProductionSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            NepalLocationSeeder::class,
            AmenitySeeder::class,
            TrustScoreFactorSeeder::class,
        ]);

        $email = env('PRODUCTION_ADMIN_EMAIL');
        $password = env('PRODUCTION_ADMIN_PASSWORD');
        if (! $email || ! $password) {
            throw new RuntimeException(
                'Set PRODUCTION_ADMIN_EMAIL and PRODUCTION_ADMIN_PASSWORD before running ProductionSeeder.',
            );
        }

        $admin = User::query()->updateOrCreate(
            ['email' => $email],
            [
                'name' => 'Admin',
                'password' => $password,
                'email_verified_at' => now(),
            ],
        );
        $admin->roles()->syncWithoutDetaching(Role::where('key', Role::ADMIN)->pluck('id'));
    }
}

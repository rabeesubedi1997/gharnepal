<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        $roles = [
            ['key' => Role::BUYER, 'name' => 'Buyer / Renter'],
            ['key' => Role::OWNER, 'name' => 'Property Owner'],
            ['key' => Role::AGENT, 'name' => 'Agent'],
            ['key' => Role::AGENCY_ADMIN, 'name' => 'Agency Admin'],
            ['key' => Role::ADMIN, 'name' => 'Administrator'],
        ];

        foreach ($roles as $role) {
            Role::query()->updateOrCreate(['key' => $role['key']], $role);
        }
    }
}

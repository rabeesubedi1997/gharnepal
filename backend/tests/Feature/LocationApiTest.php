<?php

namespace Tests\Feature;

use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LocationApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_provinces_are_listed(): void
    {
        $this->getJson('/api/v1/locations/provinces')
            ->assertOk()
            ->assertJsonCount(3, 'data');
    }

    public function test_municipalities_can_be_filtered_by_district(): void
    {
        $kathmandu = \App\Models\District::where('code', 'D-KTM')->firstOrFail();

        $response = $this->getJson("/api/v1/locations/municipalities?district_id={$kathmandu->id}");

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.code', 'M-KTM');
    }

    public function test_wards_are_generated_for_each_municipality(): void
    {
        $kathmandu = \App\Models\Municipality::where('code', 'M-KTM')->firstOrFail();

        $response = $this->getJson("/api/v1/locations/wards?municipality_id={$kathmandu->id}");

        $response->assertOk()->assertJsonCount(32, 'data');
    }
}

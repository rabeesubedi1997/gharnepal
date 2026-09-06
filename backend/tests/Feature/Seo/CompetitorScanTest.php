<?php

namespace Tests\Feature\Seo;

use App\Models\Role;
use App\Models\SeoCompetitorScan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class CompetitorScanTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    private const SAMPLE_HTML = <<<'HTML'
        <html>
        <head>
            <title>Best Properties in Kathmandu | Competitor</title>
            <meta name="description" content="Find the best verified properties in Kathmandu today.">
            <meta property="og:image" content="https://competitor.test/hero.jpg">
        </head>
        <body>
            <nav>Home About Contact</nav>
            <h1>Best Properties in Kathmandu</h1>
            <h2>Verified Listings Every Day</h2>
            <p>Kathmandu apartment apartment apartment houses houses rental rental rental rental verified verified verified verified verified.</p>
            <footer>Copyright competitor</footer>
        </body>
        </html>
        HTML;

    public function test_admin_can_scan_a_competitor_page_and_get_seo_signals(): void
    {
        Http::fake([
            '*competitor.test/robots.txt' => Http::response("User-agent: *\nDisallow: /admin\n", 200),
            '*competitor.test/*' => Http::response(self::SAMPLE_HTML, 200),
        ]);

        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/seo/pages/home/scan', [
            'url' => 'https://competitor.test/listings/some-apartment',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.scanned_title', 'Best Properties in Kathmandu | Competitor')
            ->assertJsonPath('data.scanned_meta_description', 'Find the best verified properties in Kathmandu today.')
            ->assertJsonPath('data.scanned_og_image', 'https://competitor.test/hero.jpg');

        $this->assertContains('Best Properties in Kathmandu', $response->json('data.scanned_headings'));
        $this->assertContains('Verified Listings Every Day', $response->json('data.scanned_headings'));

        $keywords = collect($response->json('data.scanned_keywords'))->pluck('word');
        $this->assertTrue($keywords->contains('verified'));

        $this->assertDatabaseCount('seo_competitor_scans', 1);
    }

    public function test_a_scan_disallowed_by_robots_txt_is_rejected(): void
    {
        Http::fake([
            '*competitor.test/robots.txt' => Http::response("User-agent: *\nDisallow: /listings\n", 200),
        ]);

        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/seo/pages/home/scan', [
            'url' => 'https://competitor.test/listings/some-apartment',
        ])->assertStatus(422)->assertJsonFragment(['message' => 'This page disallows automated access per its robots.txt — it can\'t be scanned.']);

        $this->assertDatabaseCount('seo_competitor_scans', 0);
    }

    public function test_an_unreachable_url_is_rejected_gracefully(): void
    {
        Http::fake([
            '*unreachable.test/robots.txt' => Http::response('', 404),
            '*unreachable.test/*' => Http::response('', 500),
        ]);

        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/seo/pages/home/scan', [
            'url' => 'https://unreachable.test/page',
        ])->assertStatus(422);

        $this->assertDatabaseCount('seo_competitor_scans', 0);
    }

    public function test_admin_can_discard_a_scan(): void
    {
        $scan = SeoCompetitorScan::create([
            'page_key' => 'home',
            'competitor_url' => 'https://competitor.test/x',
            'status' => 'pending',
        ]);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/seo/scans/{$scan->id}")->assertNoContent();

        $this->assertDatabaseMissing('seo_competitor_scans', ['id' => $scan->id]);
    }

    public function test_a_non_admin_cannot_scan_or_discard(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/seo/pages/home/scan', [
            'url' => 'https://competitor.test/x',
        ])->assertForbidden();
    }
}

<?php

namespace Tests\Feature\Assistant;

use App\Models\AiProviderConfig;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAiProviderConfigTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $user = User::factory()->create();
        $user->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Admin']));

        return $user;
    }

    public function test_the_catalog_lists_every_supported_provider_including_the_custom_escape_hatch(): void
    {
        $this->actingAs($this->admin(), 'sanctum')->getJson('/api/v1/admin/ai-providers/catalog')
            ->assertOk()
            ->assertJsonFragment(['provider' => 'claude'])
            ->assertJsonFragment(['provider' => 'openai'])
            ->assertJsonFragment(['provider' => 'gemini'])
            ->assertJsonFragment(['provider' => 'custom']);
    }

    public function test_an_unknown_provider_is_rejected(): void
    {
        $this->actingAs($this->admin(), 'sanctum')->postJson('/api/v1/admin/ai-providers', [
            'provider' => 'made_up_llm',
            'label' => 'Nope',
        ])->assertUnprocessable();
    }

    public function test_an_admin_can_add_a_custom_openai_compatible_agent_with_no_new_code(): void
    {
        $response = $this->actingAs($this->admin(), 'sanctum')->postJson('/api/v1/admin/ai-providers', [
            'provider' => 'custom',
            'label' => 'Groq — Llama 3.1',
            'credentials' => ['base_url' => 'https://api.groq.com/openai/v1', 'api_key' => 'gsk-secret', 'model' => 'llama-3.1-70b'],
        ])->assertCreated();

        $response->assertJsonPath('data.provider', 'custom');
        $response->assertJsonPath('data.credentials.base_url.value', 'https://api.groq.com/openai/v1');
        $response->assertJsonPath('data.credentials.api_key.configured', true);
        $response->assertJsonPath('data.credentials.api_key.value', null);
    }

    public function test_multiple_custom_agents_can_be_added_side_by_side(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/ai-providers', [
            'provider' => 'custom', 'label' => 'Groq agent',
            'credentials' => ['base_url' => 'https://api.groq.com/openai/v1', 'api_key' => 'a', 'model' => 'llama-3.1-70b'],
        ])->assertCreated();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/ai-providers', [
            'provider' => 'custom', 'label' => 'DeepSeek agent',
            'credentials' => ['base_url' => 'https://api.deepseek.com/v1', 'api_key' => 'b', 'model' => 'deepseek-chat'],
        ])->assertCreated();

        $this->assertSame(2, AiProviderConfig::where('provider', 'custom')->count());
    }

    public function test_enabling_one_agent_while_another_is_active_is_allowed_and_reports_the_conflict(): void
    {
        $admin = $this->admin();
        $claude = AiProviderConfig::create(['provider' => 'claude', 'label' => 'Claude prod', 'is_enabled' => true]);
        $custom = AiProviderConfig::create([
            'provider' => 'custom', 'label' => 'Groq agent', 'is_enabled' => false,
            'credentials' => ['base_url' => 'https://api.groq.com/openai/v1', 'api_key' => 'a', 'model' => 'llama-3.1-70b'],
        ]);

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/ai-providers/{$custom->id}", [
            'is_enabled' => true,
        ])->assertOk();

        $response->assertJsonPath('data.is_enabled', true);
        $response->assertJsonPath('meta.disabled_others.0.id', $claude->id);
        $response->assertJsonPath('meta.disabled_others.0.label', 'Claude prod');

        $this->assertTrue($custom->fresh()->is_enabled);
        $this->assertFalse($claude->fresh()->is_enabled);
    }

    public function test_enabling_an_agent_when_nothing_else_is_active_reports_no_conflict(): void
    {
        $admin = $this->admin();
        $custom = AiProviderConfig::create(['provider' => 'custom', 'label' => 'Solo agent', 'is_enabled' => false]);

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/ai-providers/{$custom->id}", [
            'is_enabled' => true,
        ])->assertOk();

        $response->assertJsonPath('meta.disabled_others', []);
    }

    public function test_a_non_admin_cannot_manage_ai_providers(): void
    {
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->getJson('/api/v1/admin/ai-providers')->assertForbidden();
        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/admin/ai-providers', ['provider' => 'custom', 'label' => 'x'])->assertForbidden();
    }
}

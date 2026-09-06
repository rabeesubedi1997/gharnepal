<?php

namespace Tests\Feature\Blog;

use App\Models\BlogPost;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BlogPostTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_the_public_list_only_shows_published_posts(): void
    {
        BlogPost::create(['title' => 'Published One', 'slug' => 'published-one', 'body' => 'Body text here.', 'status' => 'published', 'published_at' => now()]);
        BlogPost::create(['title' => 'Draft One', 'slug' => 'draft-one', 'body' => 'Body text here.', 'status' => 'draft']);

        $response = $this->getJson('/api/v1/blog');

        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title');
        $this->assertTrue($titles->contains('Published One'));
        $this->assertFalse($titles->contains('Draft One'));
    }

    public function test_a_draft_post_is_not_reachable_by_slug_publicly(): void
    {
        BlogPost::create(['title' => 'Draft Two', 'slug' => 'draft-two', 'body' => 'Body text here.', 'status' => 'draft']);

        $this->getJson('/api/v1/blog/draft-two')->assertNotFound();
    }

    public function test_a_published_post_shows_its_seo_and_body(): void
    {
        $post = BlogPost::create(['title' => 'How to Verify a Lalpurja', 'slug' => 'how-to-verify-a-lalpurja', 'body' => 'Full article body.', 'status' => 'published', 'published_at' => now()]);

        $response = $this->getJson("/api/v1/blog/{$post->slug}");

        $response->assertOk()
            ->assertJsonPath('data.title', 'How to Verify a Lalpurja')
            ->assertJsonPath('data.body', 'Full article body.')
            ->assertJsonPath('data.seo.structured_data.@type', 'Article');
    }

    public function test_admin_can_create_a_post_with_a_cover_image(): void
    {
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->post('/api/v1/admin/blog', [
            'title' => 'Understanding Land Classification in Nepal',
            'body' => 'Long-form article body goes here.',
            'status' => 'published',
            'cover_image' => UploadedFile::fake()->image('cover.jpg', 1200, 630),
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.slug', 'understanding-land-classification-in-nepal')
            ->assertJsonPath('data.status', 'published');
        $this->assertNotNull($response->json('data.published_at'));
        Storage::disk('public')->assertExists(BlogPost::first()->cover_image_path);
    }

    public function test_a_duplicate_title_gets_a_unique_slug(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/blog', ['title' => 'Same Title', 'body' => 'First.', 'status' => 'draft'])
            ->assertJsonPath('data.slug', 'same-title');

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/blog', ['title' => 'Same Title', 'body' => 'Second.', 'status' => 'draft'])
            ->assertJsonPath('data.slug', 'same-title-2');
    }

    public function test_admin_can_update_a_post_and_replace_its_cover_image(): void
    {
        $admin = $this->admin();
        $post = BlogPost::create(['title' => 'Old', 'slug' => 'old-post', 'body' => 'Old body.', 'status' => 'draft', 'cover_image_path' => 'blog/old.jpg']);
        Storage::disk('public')->put('blog/old.jpg', 'fake');

        $response = $this->actingAs($admin, 'sanctum')->post("/api/v1/admin/blog/{$post->id}", [
            '_method' => 'PUT',
            'title' => 'New Title',
            'cover_image' => UploadedFile::fake()->image('new.jpg'),
        ]);

        $response->assertOk()->assertJsonPath('data.title', 'New Title');
        $post->refresh();
        $this->assertNotSame('blog/old.jpg', $post->cover_image_path);
        Storage::disk('public')->assertMissing('blog/old.jpg');
    }

    public function test_admin_can_delete_a_post(): void
    {
        $admin = $this->admin();
        $post = BlogPost::create(['title' => 'To Delete', 'slug' => 'to-delete', 'body' => 'Body.', 'status' => 'draft']);

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/blog/{$post->id}")->assertNoContent();

        $this->assertDatabaseMissing('blog_posts', ['id' => $post->id]);
    }

    public function test_a_non_admin_cannot_manage_blog_posts(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/blog')->assertForbidden();
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/blog', [])->assertForbidden();
    }
}

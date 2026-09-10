<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\BlogPostResource;
use App\Models\BlogPost;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class BlogPostController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return BlogPostResource::collection(BlogPost::query()->with('author')->latest()->get());
    }

    public function show(BlogPost $blogPost): BlogPostResource
    {
        return new BlogPostResource($blogPost->load('author'));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'excerpt' => ['nullable', 'string', 'max:300'],
            'body' => ['required', 'string'],
            'status' => ['required', Rule::in(['draft', 'published'])],
            'cover_image' => ['nullable', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $slug = $this->uniqueSlug($data['title']);

        $post = BlogPost::create([
            ...collect($data)->except(['cover_image'])->all(),
            'slug' => $slug,
            'author_id' => $request->user()->id,
            'cover_image_path' => $request->hasFile('cover_image') ? $request->file('cover_image')->store('blog', 'public') : null,
            'published_at' => $data['status'] === 'published' ? now() : null,
        ]);

        return (new BlogPostResource($post->load('author')))->response()->setStatusCode(201);
    }

    public function update(Request $request, BlogPost $blogPost): BlogPostResource
    {
        $data = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'excerpt' => ['nullable', 'string', 'max:300'],
            'body' => ['sometimes', 'string'],
            'status' => ['sometimes', Rule::in(['draft', 'published'])],
            'cover_image' => ['sometimes', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        if ($request->hasFile('cover_image')) {
            if ($blogPost->cover_image_path) {
                Storage::disk('public')->delete($blogPost->cover_image_path);
            }
            $data['cover_image_path'] = $request->file('cover_image')->store('blog', 'public');
        }

        // Publishing for the first time stamps published_at; later edits don't bump it.
        if (($data['status'] ?? null) === 'published' && ! $blogPost->published_at) {
            $data['published_at'] = now();
        }

        $blogPost->update(collect($data)->except('cover_image')->all());

        return new BlogPostResource($blogPost->fresh('author'));
    }

    public function destroy(BlogPost $blogPost): Response
    {
        if ($blogPost->cover_image_path) {
            Storage::disk('public')->delete($blogPost->cover_image_path);
        }
        $blogPost->delete();

        return response()->noContent();
    }

    private function uniqueSlug(string $title): string
    {
        $base = Str::slug($title);
        $slug = $base;
        $i = 1;
        while (BlogPost::query()->where('slug', $slug)->exists()) {
            $slug = "{$base}-".++$i;
        }

        return $slug;
    }
}

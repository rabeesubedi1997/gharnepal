<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\BlogPostResource;
use App\Http\Resources\BlogPostSummaryResource;
use App\Models\BlogPost;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BlogController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $posts = BlogPost::query()
            ->where('status', 'published')
            ->with('author')
            ->latest('published_at')
            ->paginate(9);

        return BlogPostSummaryResource::collection($posts);
    }

    public function show(string $slug): BlogPostResource
    {
        $post = BlogPost::query()
            ->where('status', 'published')
            ->where('slug', $slug)
            ->with('author')
            ->firstOrFail();

        return new BlogPostResource($post);
    }
}

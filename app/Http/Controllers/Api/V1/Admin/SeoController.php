<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Seo\Services\CompetitorPageScraperService;
use App\Domain\Seo\Services\SeoService;
use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\SeoCompetitorScanResource;
use App\Models\Agency;
use App\Models\BlogPost;
use App\Models\Neighborhood;
use App\Models\PropertyListing;
use App\Models\SeoCompetitorScan;
use App\Models\SeoPage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;
use RuntimeException;

/**
 * A flat "page approach" to SEO: every page on the site — static/category
 * pages plus every listing/neighborhood/agency — is addressed by one
 * `page_key` string, editable one at a time. Nothing here mutates the live
 * site by itself; `store`/`update` are the only writes to `seo_pages`, and
 * a scan only ever creates a read-only reference row an admin can look at
 * and then discard.
 */
class SeoController extends Controller
{
    public function __construct(private readonly SeoService $seo) {}

    public function index(Request $request): JsonResponse
    {
        $type = $request->string('type')->value() ?: null;
        $search = mb_strtolower((string) $request->string('q')->value());

        $rows = collect();

        if (! $type || $type === 'static') {
            $overrides = SeoPage::query()->whereIn('page_key', array_keys(SeoService::STATIC_PAGES))->get()->keyBy('page_key');
            foreach (SeoService::STATIC_PAGES as $key => $def) {
                $rows->push($this->row($key, 'static', $def['label'], $def['path'], $overrides->get($key)));
            }
        }

        if (! $type || $type === 'listing') {
            $overrides = SeoPage::query()->where('page_type', 'listing')->get()->keyBy('page_key');
            PropertyListing::query()
                ->where('status', PropertyListing::STATUS_PUBLISHED)
                ->orderByDesc('published_at')
                ->get(['slug', 'title'])
                ->each(function ($listing) use ($rows, $overrides) {
                    $key = "listing:{$listing->slug}";
                    $rows->push($this->row($key, 'listing', "Listing: {$listing->title}", "/listings/{$listing->slug}", $overrides->get($key)));
                });
        }

        if (! $type || $type === 'neighborhood') {
            $overrides = SeoPage::query()->where('page_type', 'neighborhood')->get()->keyBy('page_key');
            Neighborhood::query()->orderBy('name')->get(['id', 'name'])->each(function ($n) use ($rows, $overrides) {
                $key = "neighborhood:{$n->id}";
                $rows->push($this->row($key, 'neighborhood', "Neighborhood: {$n->name}", "/neighborhoods/{$n->id}", $overrides->get($key)));
            });
        }

        if (! $type || $type === 'agency') {
            $overrides = SeoPage::query()->where('page_type', 'agency')->get()->keyBy('page_key');
            Agency::query()->orderBy('name')->get(['slug', 'name'])->each(function ($a) use ($rows, $overrides) {
                $key = "agency:{$a->slug}";
                $rows->push($this->row($key, 'agency', "Agency: {$a->name}", "/agents/{$a->slug}", $overrides->get($key)));
            });
        }

        if (! $type || $type === 'blog') {
            $overrides = SeoPage::query()->where('page_type', 'blog')->get()->keyBy('page_key');
            BlogPost::query()->orderByDesc('published_at')->get(['slug', 'title'])->each(function ($post) use ($rows, $overrides) {
                $key = "blog:{$post->slug}";
                $rows->push($this->row($key, 'blog', "Blog: {$post->title}", "/blog/{$post->slug}", $overrides->get($key)));
            });
        }

        if ($search !== '') {
            $rows = $rows->filter(fn ($r) => str_contains(mb_strtolower($r['label']), $search) || str_contains(mb_strtolower($r['page_key']), $search));
        }

        return response()->json(['data' => $rows->values()]);
    }

    public function show(string $key): JsonResponse
    {
        $effective = $this->resolveEffective($key);
        if (! $effective) {
            abort(404, 'Unknown page.');
        }

        $override = SeoPage::query()->where('page_key', $key)->first();
        $scans = SeoCompetitorScan::query()
            ->where('page_key', $key)
            ->where('status', 'pending')
            ->latest()
            ->get();

        return response()->json([
            'data' => [
                'effective' => $effective,
                'override' => $override?->only([
                    'meta_title', 'meta_description', 'meta_keywords', 'og_image_url',
                    'canonical_path', 'robots_index', 'robots_follow', 'status', 'updated_at',
                ]),
                'scans' => SeoCompetitorScanResource::collection($scans),
            ],
        ]);
    }

    public function update(Request $request, string $key): JsonResponse
    {
        $pageType = $this->pageTypeFor($key);
        if (! $pageType) {
            abort(404, 'Unknown page.');
        }

        $data = $request->validate([
            'meta_title' => ['nullable', 'string', 'max:255'],
            'meta_description' => ['nullable', 'string', 'max:320'],
            'meta_keywords' => ['nullable', 'string', 'max:500'],
            'og_image_url' => ['nullable', 'string', 'max:2048'],
            'canonical_path' => ['nullable', 'string', 'max:255', 'starts_with:/'],
            'robots_index' => ['sometimes', 'boolean'],
            'robots_follow' => ['sometimes', 'boolean'],
            'status' => ['required', Rule::in(['draft', 'published'])],
        ]);

        $label = $this->labelFor($key, $pageType);

        $page = SeoPage::query()->updateOrCreate(
            ['page_key' => $key],
            [
                ...$data,
                'page_type' => $pageType,
                'label' => $label,
                'robots_index' => $request->boolean('robots_index', true),
                'robots_follow' => $request->boolean('robots_follow', true),
                'updated_by' => $request->user()->id,
            ],
        );

        return response()->json(['data' => [
            'effective' => $this->resolveEffective($key),
            'override' => $page->only([
                'meta_title', 'meta_description', 'meta_keywords', 'og_image_url',
                'canonical_path', 'robots_index', 'robots_follow', 'status', 'updated_at',
            ]),
        ]]);
    }

    public function destroy(string $key): Response
    {
        SeoPage::query()->where('page_key', $key)->delete();

        return response()->noContent();
    }

    public function scan(Request $request, string $key, CompetitorPageScraperService $scraper): JsonResponse
    {
        if (! $this->pageTypeFor($key)) {
            abort(404, 'Unknown page.');
        }

        $data = $request->validate(['url' => ['required', 'string', 'max:1000']]);

        try {
            $result = $scraper->scan($data['url']);
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $scanRecord = SeoCompetitorScan::create([
            'page_key' => $key,
            'competitor_url' => $data['url'],
            'scanned_title' => $result['title'],
            'scanned_meta_description' => $result['meta_description'],
            'scanned_meta_keywords' => $result['meta_keywords'],
            'scanned_headings' => $result['headings'],
            'scanned_keywords' => $result['keywords'],
            'scanned_og_image' => $result['og_image'],
            'word_count' => $result['word_count'],
            'status' => 'pending',
            'scanned_by' => $request->user()->id,
        ]);

        return (new SeoCompetitorScanResource($scanRecord))->response()->setStatusCode(201);
    }

    public function discardScan(SeoCompetitorScan $scan): Response
    {
        $scan->delete();

        return response()->noContent();
    }

    private function row(string $key, string $type, string $label, string $path, ?SeoPage $override): array
    {
        return [
            'page_key' => $key,
            'page_type' => $type,
            'label' => $label,
            'path' => $path,
            'has_override' => (bool) $override,
            'status' => $override?->status,
            'updated_at' => $override?->updated_at,
        ];
    }

    private function resolveEffective(string $key): ?array
    {
        if (isset(SeoService::STATIC_PAGES[$key])) {
            return $this->seo->effectiveForStaticPage($key);
        }

        if (str_starts_with($key, 'listing:')) {
            $listing = PropertyListing::query()->where('slug', substr($key, 8))->with('property.address.municipality', 'property.address.district')->first();

            return $listing ? $this->seo->effectiveForListing($listing) : null;
        }

        if (str_starts_with($key, 'neighborhood:')) {
            $neighborhood = Neighborhood::find(substr($key, 13));

            return $neighborhood ? $this->seo->effectiveForNeighborhood($neighborhood) : null;
        }

        if (str_starts_with($key, 'agency:')) {
            $agency = Agency::query()->where('slug', substr($key, 7))->first();

            return $agency ? $this->seo->effectiveForAgency($agency) : null;
        }

        if (str_starts_with($key, 'blog:')) {
            $post = BlogPost::query()->where('slug', substr($key, 5))->with('author')->first();

            return $post ? $this->seo->effectiveForBlogPost($post) : null;
        }

        return null;
    }

    private function pageTypeFor(string $key): ?string
    {
        if (isset(SeoService::STATIC_PAGES[$key])) {
            return 'static';
        }
        if (str_starts_with($key, 'listing:') && PropertyListing::query()->where('slug', substr($key, 8))->exists()) {
            return 'listing';
        }
        if (str_starts_with($key, 'neighborhood:') && Neighborhood::query()->whereKey(substr($key, 13))->exists()) {
            return 'neighborhood';
        }
        if (str_starts_with($key, 'agency:') && Agency::query()->where('slug', substr($key, 7))->exists()) {
            return 'agency';
        }
        if (str_starts_with($key, 'blog:') && BlogPost::query()->where('slug', substr($key, 5))->exists()) {
            return 'blog';
        }

        return null;
    }

    private function labelFor(string $key, string $pageType): string
    {
        return match ($pageType) {
            'static' => SeoService::STATIC_PAGES[$key]['label'],
            'listing' => 'Listing: '.PropertyListing::where('slug', substr($key, 8))->value('title'),
            'neighborhood' => 'Neighborhood: '.Neighborhood::find(substr($key, 13))?->name,
            'agency' => 'Agency: '.Agency::where('slug', substr($key, 7))->value('name'),
            'blog' => 'Blog: '.BlogPost::where('slug', substr($key, 5))->value('title'),
            default => $key,
        };
    }
}

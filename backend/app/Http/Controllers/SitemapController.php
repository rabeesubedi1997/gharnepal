<?php

namespace App\Http\Controllers;

use App\Domain\Seo\Services\SeoService;
use App\Models\Agency;
use App\Models\BlogPost;
use App\Models\Neighborhood;
use App\Models\PropertyListing;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Cache;

/**
 * `/sitemap.xml` and `/robots.txt` — served at the site root (see routes/web.php)
 * rather than under `/api/v1`, because that's where a crawler looks for them.
 *
 * In production, if the SPA and this API are reverse-proxied under one
 * domain (the standard shape for this kind of app), route exactly these two
 * paths to the Laravel backend so they resolve on the same domain as the
 * pages they describe — everything else can stay on the SPA/static host.
 */
class SitemapController extends Controller
{
    public function index(): Response
    {
        $xml = Cache::remember('sitemap.xml', 3600, function () {
            $base = config('app.frontend_url');
            $urls = [];

            foreach (array_keys(SeoService::STATIC_PAGES) as $key) {
                $path = SeoService::STATIC_PAGES[$key]['path'];
                $urls[] = ['loc' => $base.$path, 'changefreq' => $key === 'home' ? 'daily' : 'hourly', 'priority' => $key === 'home' ? '1.0' : '0.8'];
            }

            PropertyListing::query()
                ->where('status', PropertyListing::STATUS_PUBLISHED)
                ->select(['slug', 'published_at', 'updated_at'])
                ->orderByDesc('published_at')
                ->chunk(200, function ($chunk) use (&$urls, $base) {
                    foreach ($chunk as $listing) {
                        $urls[] = [
                            'loc' => "{$base}/listings/{$listing->slug}",
                            'lastmod' => $listing->updated_at->toAtomString(),
                            'changefreq' => 'daily',
                            'priority' => '0.9',
                        ];
                    }
                });

            Neighborhood::query()->select(['id', 'updated_at'])->get()->each(function ($n) use (&$urls, $base) {
                $urls[] = ['loc' => "{$base}/neighborhoods/{$n->id}", 'lastmod' => $n->updated_at->toAtomString(), 'changefreq' => 'weekly', 'priority' => '0.5'];
            });

            Agency::query()->whereNotNull('verified_at')->where('status', 'active')->select(['slug', 'updated_at'])->get()->each(function ($a) use (&$urls, $base) {
                $urls[] = ['loc' => "{$base}/agents/{$a->slug}", 'lastmod' => $a->updated_at->toAtomString(), 'changefreq' => 'weekly', 'priority' => '0.5'];
            });

            BlogPost::query()->where('status', 'published')->select(['slug', 'updated_at'])->get()->each(function ($p) use (&$urls, $base) {
                $urls[] = ['loc' => "{$base}/blog/{$p->slug}", 'lastmod' => $p->updated_at->toAtomString(), 'changefreq' => 'monthly', 'priority' => '0.6'];
            });

            $body = collect($urls)->map(function ($u) {
                $lines = ["    <loc>".e($u['loc'])."</loc>"];
                if (! empty($u['lastmod'])) {
                    $lines[] = "    <lastmod>{$u['lastmod']}</lastmod>";
                }
                $lines[] = "    <changefreq>{$u['changefreq']}</changefreq>";
                $lines[] = "    <priority>{$u['priority']}</priority>";

                return "  <url>\n".implode("\n", $lines)."\n  </url>";
            })->implode("\n");

            return '<?xml version="1.0" encoding="UTF-8"?>'."\n".
                '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'."\n".
                $body."\n".
                '</urlset>';
        });

        return response($xml, 200)->header('Content-Type', 'application/xml; charset=UTF-8');
    }

    public function robots(): Response
    {
        $base = config('app.frontend_url');

        $body = implode("\n", [
            'User-agent: *',
            'Disallow: /admin',
            'Disallow: /dashboard',
            'Disallow: /account',
            'Disallow: /login',
            'Disallow: /register',
            'Disallow: /post-property',
            'Disallow: /messages',
            'Disallow: /saved',
            '',
            "Sitemap: {$base}/sitemap.xml",
        ]);

        return response($body, 200)->header('Content-Type', 'text/plain; charset=UTF-8');
    }
}

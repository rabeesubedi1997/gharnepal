<?php

namespace App\Domain\Seo\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Symfony\Component\DomCrawler\Crawler;

/**
 * Fetches a single competitor page (on-demand, admin-triggered — never a
 * crawl of a whole site) and extracts short SEO *signals*: the title tag,
 * meta description, heading text, and a rough keyword frequency count.
 *
 * Deliberately does NOT store the page's full body text or HTML — only
 * these short, factual metadata fields, the same class of data any SEO
 * tool (Ahrefs, SEMrush, etc.) surfaces. This is reference material for an
 * admin to read and be inspired by, never content republished verbatim.
 *
 * Honors the target's robots.txt for the fetched path before requesting it.
 */
class CompetitorPageScraperService
{
    private const USER_AGENT = 'GharNepalSeoResearchBot/1.0 (+admin-triggered single-page SEO audit)';

    private const STOPWORDS = [
        'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'has', 'was', 'were',
        'with', 'this', 'that', 'from', 'your', 'our', 'their', 'about', 'into', 'more',
        'have', 'will', 'a', 'an', 'in', 'on', 'of', 'to', 'is', 'it', 'as', 'at', 'by', 'be',
        'or', 'we', 'us', 'if', 'so', 'per', 'nepal', 'property', 'properties',
    ];

    /**
     * @return array{title:?string,meta_description:?string,headings:string[],keywords:array<int,array{word:string,count:int}>,og_image:?string}
     *
     * @throws RuntimeException when the URL is invalid, disallowed by robots.txt, or unreachable.
     */
    public function scan(string $url): array
    {
        $this->assertScannable($url);

        try {
            $response = Http::withUserAgent(self::USER_AGENT)
                ->timeout(8)
                ->connectTimeout(5)
                ->get($url);
        } catch (ConnectionException) {
            throw new RuntimeException('Could not reach that URL — check it\'s correct and publicly accessible.');
        }

        if (! $response->successful()) {
            throw new RuntimeException("The page responded with HTTP {$response->status()}.");
        }

        $crawler = new Crawler($response->body());

        return [
            'title' => $this->text($crawler, 'title'),
            'meta_description' => $this->metaContent($crawler, 'description'),
            'headings' => $this->headings($crawler),
            'keywords' => $this->keywords($crawler),
            'og_image' => $this->metaContent($crawler, 'og:image', property: true),
        ];
    }

    private function assertScannable(string $url): void
    {
        if (! filter_var($url, FILTER_VALIDATE_URL) || ! in_array(parse_url($url, PHP_URL_SCHEME), ['http', 'https'], true)) {
            throw new RuntimeException('Enter a full valid URL, e.g. https://example.com/listings/some-property');
        }

        $host = parse_url($url, PHP_URL_HOST);
        $path = parse_url($url, PHP_URL_PATH) ?: '/';
        if (in_array($host, ['localhost', '127.0.0.1'], true)) {
            throw new RuntimeException('Refusing to scan a local address.');
        }

        if ($this->isDisallowedByRobots($url, $host, $path)) {
            throw new RuntimeException('This page disallows automated access per its robots.txt — it can\'t be scanned.');
        }
    }

    private function isDisallowedByRobots(string $url, string $host, string $path): bool
    {
        $scheme = parse_url($url, PHP_URL_SCHEME);

        try {
            $robots = Http::withUserAgent(self::USER_AGENT)->timeout(5)->get("{$scheme}://{$host}/robots.txt");
        } catch (ConnectionException) {
            return false; // no robots.txt reachable — nothing to honor, proceed
        }

        if (! $robots->successful()) {
            return false;
        }

        $applies = false;
        foreach (explode("\n", $robots->body()) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }
            if (preg_match('/^user-agent:\s*(.+)$/i', $line, $m)) {
                $applies = trim($m[1]) === '*';
                continue;
            }
            if ($applies && preg_match('/^disallow:\s*(.+)$/i', $line, $m)) {
                $rule = trim($m[1]);
                if ($rule !== '' && str_starts_with($path, $rule)) {
                    return true;
                }
            }
        }

        return false;
    }

    private function text(Crawler $crawler, string $selector): ?string
    {
        $node = $crawler->filter($selector);

        return $node->count() ? trim($node->first()->text()) : null;
    }

    private function metaContent(Crawler $crawler, string $name, bool $property = false): ?string
    {
        $attr = $property ? 'property' : 'name';
        $node = $crawler->filter("meta[{$attr}=\"{$name}\"]");

        return $node->count() ? $node->first()->attr('content') : null;
    }

    /** @return string[] */
    private function headings(Crawler $crawler): array
    {
        $headings = $crawler->filter('h1, h2')->each(fn (Crawler $node) => trim($node->text()));

        return collect($headings)
            ->filter(fn ($h) => $h !== '')
            ->unique()
            ->take(15)
            ->values()
            ->all();
    }

    /** @return array<int,array{word:string,count:int}> */
    private function keywords(Crawler $crawler): array
    {
        // Strip non-content tags so nav/footer boilerplate doesn't dominate the count.
        $crawler->filter('script, style, nav, footer, header, noscript')->each(
            fn (Crawler $node) => $node->getNode(0)?->parentNode?->removeChild($node->getNode(0)),
        );

        $bodyNode = $crawler->filter('body');
        $text = $bodyNode->count() ? $bodyNode->first()->text() : '';
        $text = strtolower(preg_replace('/[^a-zA-Z\s]/', ' ', $text) ?? '');

        $counts = [];
        foreach (preg_split('/\s+/', $text) ?: [] as $word) {
            if (strlen($word) < 4 || in_array($word, self::STOPWORDS, true)) {
                continue;
            }
            $counts[$word] = ($counts[$word] ?? 0) + 1;
        }

        arsort($counts);

        return collect(array_slice($counts, 0, 15, true))
            ->map(fn ($count, $word) => ['word' => $word, 'count' => $count])
            ->values()
            ->all();
    }
}

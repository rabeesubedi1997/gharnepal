<?php

namespace App\Domain\Properties\Support;

/**
 * Turns a plain YouTube/Vimeo link into a safe, iframe-embeddable URL.
 *
 * Deliberately an allowlist of two known video hosts rather than accepting
 * any URL: a listing's video field renders inside an <iframe> on the public
 * listing page, so an arbitrary attacker-supplied URL there would be an open
 * invitation to embed anything (including something that phishes visitors
 * under gharnepal.com's own page). Unrecognized hosts are rejected at
 * validation time (see StorePropertyListingRequest) rather than silently
 * dropped here.
 */
class VideoUrl
{
    public static function toEmbedUrl(?string $url): ?string
    {
        if (! $url) {
            return null;
        }

        $host = strtolower((string) parse_url($url, PHP_URL_HOST));
        $host = preg_replace('/^www\./', '', $host);
        $path = (string) parse_url($url, PHP_URL_PATH);

        if ($host === 'youtu.be') {
            $id = ltrim($path, '/');

            return $id !== '' ? "https://www.youtube.com/embed/{$id}" : null;
        }

        if ($host === 'youtube.com' || $host === 'm.youtube.com') {
            parse_str((string) parse_url($url, PHP_URL_QUERY), $query);
            $id = $query['v'] ?? null;

            if (! $id && preg_match('#^/embed/([^/?]+)#', $path, $m)) {
                $id = $m[1];
            }

            return $id ? "https://www.youtube.com/embed/{$id}" : null;
        }

        if ($host === 'vimeo.com') {
            $id = ltrim($path, '/');

            return ($id !== '' && ctype_digit($id)) ? "https://player.vimeo.com/video/{$id}" : null;
        }

        return null;
    }

    public static function isSupported(?string $url): bool
    {
        return self::toEmbedUrl($url) !== null;
    }
}

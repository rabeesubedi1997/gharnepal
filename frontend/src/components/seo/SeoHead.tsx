import { Helmet } from 'react-helmet-async'
import type { EffectiveSeo } from '../../lib/api/seo'

/**
 * Renders the actual <title>/meta/canonical/OG/JSON-LD tags for one page from
 * an already-fetched effective SEO object (admin override merged with an
 * auto-generated default — see backend SeoService). Nothing here decides
 * content; it only renders what the API already resolved.
 */
export function SeoHead({ seo }: { seo: EffectiveSeo | undefined }) {
  if (!seo) return null

  const robotsContent = [seo.robots.index ? 'index' : 'noindex', seo.robots.follow ? 'follow' : 'nofollow'].join(', ')

  return (
    <Helmet>
      <title>{seo.title}</title>
      {seo.description && <meta name="description" content={seo.description} />}
      {seo.keywords && <meta name="keywords" content={seo.keywords} />}
      <link rel="canonical" href={seo.canonical_url} />
      <meta name="robots" content={robotsContent} />

      <meta property="og:type" content={seo.page_type === 'listing' ? 'product' : 'website'} />
      <meta property="og:title" content={seo.title} />
      {seo.description && <meta property="og:description" content={seo.description} />}
      <meta property="og:url" content={seo.canonical_url} />
      {seo.og_image && <meta property="og:image" content={seo.og_image} />}
      <meta name="twitter:card" content={seo.og_image ? 'summary_large_image' : 'summary'} />

      {seo.structured_data && <script type="application/ld+json">{JSON.stringify(seo.structured_data)}</script>}
    </Helmet>
  )
}

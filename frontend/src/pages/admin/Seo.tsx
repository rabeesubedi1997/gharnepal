import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ExternalLink, Search as SearchIcon } from 'lucide-react'
import { useAdminSeoPages } from '../../lib/api/seo'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Input, Select } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const TYPE_LABEL: Record<string, string> = {
  static: 'Static / category page',
  listing: 'Listing',
  neighborhood: 'Neighborhood',
  agency: 'Agency',
}

export function Seo() {
  const [type, setType] = useState('')
  const [q, setQ] = useState('')
  const { data, isPending, isError, refetch } = useAdminSeoPages({ type: type || undefined, q: q || undefined })

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl font-semibold text-ink-900">SEO</h1>
        <p className="mt-1 text-sm text-ink-700/70">
          Every page on the site, one at a time. Edit a page's title, description, and social preview — nothing
          changes on the live site until you publish it here.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="relative w-full max-w-xs">
          <SearchIcon className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-700/40" aria-hidden="true" />
          <Input
            placeholder="Search pages"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            className="pl-9"
            aria-label="Search pages"
          />
        </div>
        <Select value={type} onChange={(e) => setType(e.target.value)} aria-label="Filter by page type" className="w-auto">
          <option value="">All page types</option>
          <option value="static">Static / category pages</option>
          <option value="listing">Listings</option>
          <option value="neighborhood">Neighborhoods</option>
          <option value="agency">Agencies</option>
        </Select>
      </div>

      {isPending && <PropertyGridSkeleton count={6} />}
      {isError && <ErrorState onRetry={refetch} description="Couldn't load pages right now." />}
      {!isPending && !isError && data?.length === 0 && (
        <EmptyState title="No pages match" description="Try a different search term or page type." />
      )}

      {!isPending && !isError && data && data.length > 0 && (
        <div className="flex flex-col gap-2">
          {data.map((row) => (
            <Link key={row.page_key} to={`/admin/seo/${encodeURIComponent(row.page_key)}`}>
              <Card className="flex flex-wrap items-center justify-between gap-3 p-3 transition-shadow hover:shadow-md">
                <div className="min-w-0">
                  <p className="truncate font-medium text-ink-900">{row.label}</p>
                  <p className="flex items-center gap-1 text-xs text-ink-700/60">
                    {row.path} <ExternalLink className="h-3 w-3" aria-hidden="true" />
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Badge tone="neutral">{TYPE_LABEL[row.page_type] ?? row.page_type}</Badge>
                  {!row.has_override && <Badge tone="neutral">Using defaults</Badge>}
                  {row.has_override && row.status === 'published' && <Badge tone="trust">Published override</Badge>}
                  {row.has_override && row.status === 'draft' && <Badge tone="warning">Draft override</Badge>}
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

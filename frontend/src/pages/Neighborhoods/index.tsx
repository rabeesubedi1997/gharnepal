import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { MapPin, ShieldCheck } from 'lucide-react'
import { useNeighborhoodList } from '../../lib/api/neighborhoods'
import { useStaticPageSeo } from '../../lib/api/seo'
import { SeoHead } from '../../components/seo/SeoHead'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Input } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function NeighborhoodDirectory() {
  const { data, isPending, isError, refetch } = useNeighborhoodList()
  const { data: seo } = useStaticPageSeo('neighborhoods')
  const [query, setQuery] = useState('')

  const filtered = useMemo(() => {
    if (!data) return []
    const q = query.trim().toLowerCase()
    if (!q) return data
    return data.filter((n) => n.name.toLowerCase().includes(q) || n.ward?.municipality?.toLowerCase().includes(q))
  }, [data, query])

  return (
    <div className="flex flex-col gap-6">
      <SeoHead seo={seo} />
      <div>
        <h1 className="font-display text-2xl font-semibold text-ink-900">Explore neighborhoods</h1>
        <p className="mt-1 text-sm text-ink-700/70">
          Admin-curated livability scores and local knowledge for MVP cities — transport, schools, safety, and more.
          Neighborhoods without a curated score yet are still listed so you can request coverage.
        </p>
      </div>

      <Input
        placeholder="Search by neighborhood or city"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        className="max-w-sm"
        aria-label="Search neighborhoods"
      />

      {isPending && <PropertyGridSkeleton count={9} />}
      {isError && <ErrorState onRetry={refetch} description="Couldn't load neighborhoods right now." />}

      {!isPending && !isError && filtered.length === 0 && (
        <EmptyState title="No neighborhoods found" description="Try a different search term." />
      )}

      {!isPending && !isError && filtered.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map((n) => (
            <Link key={n.id} to={`/neighborhoods/${n.id}`}>
              <Card className="flex h-full flex-col gap-2 p-4 transition-shadow hover:shadow-md">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="font-display text-base font-semibold text-ink-900">{n.name}</p>
                    <p className="flex items-center gap-1 text-xs text-ink-700/60">
                      <MapPin className="h-3 w-3" aria-hidden="true" />
                      {n.ward?.municipality ?? 'Unknown city'}
                    </p>
                  </div>
                  {n.score && (
                    <span className="inline-flex items-center gap-1 rounded-full bg-trust-100 px-2.5 py-1 text-xs font-semibold text-trust-700">
                      {n.score.overall_score}/10
                    </span>
                  )}
                </div>
                {n.is_curated ? (
                  <Badge tone="trust">
                    <ShieldCheck className="h-3 w-3" aria-hidden="true" /> Admin-curated
                  </Badge>
                ) : (
                  <Badge tone="neutral">Not yet curated</Badge>
                )}
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

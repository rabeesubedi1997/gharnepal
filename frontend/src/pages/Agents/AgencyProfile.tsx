import { Link, useParams } from 'react-router-dom'
import { Building2, ShieldCheck, Users } from 'lucide-react'
import { useAgency } from '../../lib/api/agencies'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'
import { PropertyCard } from '../../components/property/PropertyCard'
import { SeoHead } from '../../components/seo/SeoHead'

export function AgencyProfile() {
  const { slug } = useParams<{ slug: string }>()
  const { data: agency, isPending, isError, refetch } = useAgency(slug)

  if (isPending) {
    return (
      <div className="flex flex-col gap-4">
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  if (isError || !agency) {
    return <ErrorState title="Agency not found" description="This agency may not be verified or no longer exists." onRetry={refetch} />
  }

  return (
    <div className="flex flex-col gap-6">
      <SeoHead seo={agency.seo} />
      <Link to="/agents" className="text-sm text-link-600 hover:text-link-700">
        &larr; All agents
      </Link>

      <Card className="flex flex-col gap-4 p-5 sm:flex-row sm:items-start">
        {agency.logo_url ? (
          <img src={agency.logo_url} alt="" className="h-20 w-20 shrink-0 rounded-full object-cover" />
        ) : (
          <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full bg-trust-100 text-trust-700">
            <Building2 className="h-10 w-10" aria-hidden="true" />
          </div>
        )}
        <div className="flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="font-display text-2xl font-semibold text-ink-900">{agency.name}</h1>
            {agency.is_verified && (
              <Badge tone="trust">
                <ShieldCheck className="h-3 w-3" /> Verified agency
              </Badge>
            )}
          </div>
          {agency.description && <p className="mt-2 text-sm text-ink-700/80">{agency.description}</p>}
          <p className="mt-3 flex items-center gap-1 text-xs text-ink-700/60">
            <Users className="h-3.5 w-3.5" aria-hidden="true" /> {agency.member_count} agent{agency.member_count === 1 ? '' : 's'}
          </p>
          {agency.members.length > 0 && (
            <ul className="mt-2 flex flex-wrap gap-2">
              {agency.members.map((m, i) => (
                <li key={i} className="rounded-full bg-stone-100 px-3 py-1 text-xs text-ink-700">
                  {m.name}
                  {m.role_in_agency === 'owner_admin' && <span className="ml-1 text-ink-700/50">· admin</span>}
                </li>
              ))}
            </ul>
          )}
        </div>
      </Card>

      <div>
        <h2 className="mb-3 font-display text-lg font-semibold text-ink-900">Active listings</h2>
        {agency.active_listings.length === 0 ? (
          <EmptyState title="No active listings" description="This agency doesn't have any published listings right now." />
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {agency.active_listings.map((listing) => (
              <PropertyCard key={listing.id} listing={listing} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

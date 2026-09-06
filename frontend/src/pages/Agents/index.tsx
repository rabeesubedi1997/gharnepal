import { Link } from 'react-router-dom'
import { Building2, ShieldCheck, Users } from 'lucide-react'
import { useAgencies } from '../../lib/api/agencies'
import { useStaticPageSeo } from '../../lib/api/seo'
import { SeoHead } from '../../components/seo/SeoHead'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function AgentDirectory() {
  const { data: agencies, isPending, isError, refetch } = useAgencies()
  const { data: seo } = useStaticPageSeo('agents')

  return (
    <div className="flex flex-col gap-6">
      <SeoHead seo={seo} />
      <div>
        <h1 className="font-display text-2xl font-semibold text-ink-900">Find a verified agent</h1>
        <p className="mt-1 text-sm text-ink-700/70">
          Every agency listed here has been reviewed and verified by our admin team — browse their active
          listings or reach out directly.
        </p>
      </div>

      {isPending && <PropertyGridSkeleton count={6} />}
      {isError && <ErrorState onRetry={refetch} description="Couldn't load agencies right now." />}

      {!isPending && !isError && agencies?.length === 0 && (
        <EmptyState
          title="No verified agencies yet"
          description="Agencies appear here once an admin has reviewed and verified their registration."
        />
      )}

      {!isPending && !isError && agencies && agencies.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {agencies.map((agency) => (
            <Link key={agency.id} to={`/agents/${agency.slug}`}>
              <Card className="flex h-full flex-col gap-3 p-4 transition-shadow hover:shadow-md">
                <div className="flex items-center gap-3">
                  {agency.logo_url ? (
                    <img src={agency.logo_url} alt="" className="h-12 w-12 rounded-full object-cover" />
                  ) : (
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-trust-100 text-trust-700">
                      <Building2 className="h-6 w-6" aria-hidden="true" />
                    </div>
                  )}
                  <div className="min-w-0">
                    <p className="truncate font-display text-base font-semibold text-ink-900">{agency.name}</p>
                    {agency.is_verified && (
                      <Badge tone="trust">
                        <ShieldCheck className="h-3 w-3" /> Verified
                      </Badge>
                    )}
                  </div>
                </div>
                {agency.description && <p className="line-clamp-2 text-sm text-ink-700/70">{agency.description}</p>}
                <div className="mt-auto flex items-center gap-4 border-t border-stone-100 pt-3 text-xs text-ink-700/60">
                  <span className="flex items-center gap-1">
                    <Users className="h-3.5 w-3.5" aria-hidden="true" /> {agency.member_count} agent{agency.member_count === 1 ? '' : 's'}
                  </span>
                  <span>{agency.active_listings_count} active listing{agency.active_listings_count === 1 ? '' : 's'}</span>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

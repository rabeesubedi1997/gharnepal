import { useState } from 'react'
import { Link } from 'react-router-dom'
import { isAxiosError } from 'axios'
import {
  Building2,
  Calendar,
  CalendarClock,
  Home as HomeIcon,
  MessageCircle,
  Plus,
  Search,
  ShieldCheck,
  Wallet,
} from 'lucide-react'
import { useCurrentUser } from '../lib/api/auth'
import {
  useAgencyInquiries,
  useAgencyListings,
  useAgencyOverview,
  useAgencySiteVisits,
} from '../lib/api/agencyDashboard'
import { formatNprCompact } from '../design-system/tokens'
import { Card } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { ButtonLink } from '../components/ui/Button'
import { Skeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'

const CATEGORIES = [
  { value: '', label: 'All properties' },
  { value: 'houses', label: 'Houses & Apartments' },
  { value: 'land', label: 'Land & Plots' },
  { value: 'commercial', label: 'Commercial' },
]

export function AgencyDashboard() {
  const { data: me } = useCurrentUser()
  const [category, setCategory] = useState('')
  const [search, setSearch] = useState('')
  const [sort, setSort] = useState('newest')
  const [page, setPage] = useState(1)

  const enabled = !!me?.agency
  const overview = useAgencyOverview(enabled)
  const listings = useAgencyListings({ category: category || undefined, search: search || undefined, sort, page }, enabled)
  const inquiries = useAgencyInquiries(enabled)
  const siteVisits = useAgencySiteVisits(enabled)

  if (me && !me.agency) {
    return (
      <EmptyState
        icon={<Building2 className="h-10 w-10" />}
        title="No agency dashboard for your account"
        description="This dashboard is for members of a registered agency. If you manage an agency, ask an admin to add you as a member."
      />
    )
  }

  if (overview.isError) {
    const notFound = isAxiosError(overview.error) && overview.error.response?.status === 404
    return (
      <ErrorState
        title={notFound ? 'No agency membership found' : 'Something went wrong'}
        description={notFound ? "You're not currently listed as a member of any agency." : undefined}
        onRetry={notFound ? undefined : () => overview.refetch()}
      />
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <AgencyHeader overview={overview.data} isPending={overview.isPending} />
      <StatTiles overview={overview.data} isPending={overview.isPending} />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="flex flex-col gap-4 lg:col-span-2">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex flex-wrap gap-1.5">
              {CATEGORIES.map((c) => (
                <button
                  key={c.value}
                  type="button"
                  onClick={() => {
                    setCategory(c.value)
                    setPage(1)
                  }}
                  className={
                    category === c.value
                      ? 'rounded-lg bg-trust-700 px-3 py-1.5 text-xs font-semibold text-white'
                      : 'rounded-lg border border-stone-200 px-3 py-1.5 text-xs font-medium text-ink-700 hover:bg-stone-100'
                  }
                >
                  {c.label}
                </button>
              ))}
            </div>
            <ButtonLink to="/post-property" size="sm">
              <Plus className="h-4 w-4" /> Add New Listing
            </ButtonLink>
          </div>

          <div className="flex flex-col gap-2 sm:flex-row">
            <div className="flex flex-1 items-center gap-2 rounded-lg border border-stone-200 px-3">
              <Search className="h-4 w-4 shrink-0 text-ink-700/50" aria-hidden="true" />
              <input
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value)
                  setPage(1)
                }}
                placeholder="Search by title or reference..."
                className="h-10 w-full min-w-0 bg-transparent text-sm text-ink-900 focus:outline-none"
              />
            </div>
            <select
              value={sort}
              onChange={(e) => setSort(e.target.value)}
              className="h-10 rounded-lg border border-stone-200 px-3 text-sm text-ink-900 focus:outline-none"
            >
              <option value="newest">Newest first</option>
              <option value="leads">Most inquiries</option>
              <option value="price_high">Price: high to low</option>
              <option value="price_low">Price: low to high</option>
            </select>
          </div>

          <ListingsTable data={listings.data} isPending={listings.isPending} isError={listings.isError} onRetry={() => listings.refetch()} page={page} setPage={setPage} />
        </div>

        <div className="flex flex-col gap-6">
          <InquiriesPanel inquiries={inquiries.data} isPending={inquiries.isPending} />
          <SiteVisitsPanel visits={siteVisits.data} isPending={siteVisits.isPending} />
          <AlertReachPanel overview={overview.data} isPending={overview.isPending} />
        </div>
      </div>
    </div>
  )
}

function AgencyHeader({ overview, isPending }: { overview?: ReturnType<typeof useAgencyOverview>['data']; isPending: boolean }) {
  if (isPending || !overview) {
    return <Skeleton className="h-20 w-full" />
  }
  const { agency } = overview

  return (
    <div className="flex flex-wrap items-center gap-4">
      <span className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-trust-100 text-trust-700">
        {agency.logo_url ? <img src={agency.logo_url} alt="" className="h-full w-full object-cover" /> : <Building2 className="h-6 w-6" aria-hidden="true" />}
      </span>
      <div>
        <div className="flex flex-wrap items-center gap-2">
          <h1 className="font-display text-xl font-bold text-ink-900">{agency.name}</h1>
          {agency.is_verified && (
            <Badge tone="trust">
              <ShieldCheck className="h-3 w-3" aria-hidden="true" /> Verified agency
            </Badge>
          )}
        </div>
        <p className="text-xs text-ink-700/60">
          {[
            agency.registration_number && `Reg. ${agency.registration_number}`,
            agency.founded_year && `Operating since ${agency.founded_year}`,
            `${agency.member_count} team member${agency.member_count === 1 ? '' : 's'}`,
          ]
            .filter(Boolean)
            .join(' · ')}
        </p>
      </div>
    </div>
  )
}

function StatTiles({ overview, isPending }: { overview?: ReturnType<typeof useAgencyOverview>['data']; isPending: boolean }) {
  if (isPending || !overview) {
    return (
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-24 w-full" />
        ))}
      </div>
    )
  }

  const topCity = overview.portfolio.by_city[0]

  return (
    <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
      <Card className="p-4">
        <p className="flex items-center gap-1.5 text-xs font-medium text-ink-700/60">
          <HomeIcon className="h-3.5 w-3.5" aria-hidden="true" /> Active Portfolio
        </p>
        <p className="mt-1 font-display text-2xl font-bold text-ink-900">{overview.portfolio.active_count}</p>
        <p className="text-xs text-ink-700/60">
          {overview.portfolio.new_this_week > 0 && `+${overview.portfolio.new_this_week} this week · `}
          {topCity ? `${topCity.count} in ${topCity.city}` : 'No listings yet'}
        </p>
      </Card>
      <Card className="p-4">
        <p className="flex items-center gap-1.5 text-xs font-medium text-ink-700/60">
          <MessageCircle className="h-3.5 w-3.5" aria-hidden="true" /> Inquiries (30 Days)
        </p>
        <p className="mt-1 font-display text-2xl font-bold text-ink-900">{overview.inquiries_30d.count}</p>
        <p className="text-xs text-ink-700/60">
          {overview.inquiries_30d.response_rate_pct != null ? `${overview.inquiries_30d.response_rate_pct}% response rate` : 'No inquiries yet'}
        </p>
      </Card>
      <Card className="p-4">
        <p className="flex items-center gap-1.5 text-xs font-medium text-ink-700/60">
          <CalendarClock className="h-3.5 w-3.5" aria-hidden="true" /> Site Visits Scheduled
        </p>
        <p className="mt-1 font-display text-2xl font-bold text-ink-900">{overview.site_visits.upcoming_7d}</p>
        <p className="text-xs text-ink-700/60">{overview.site_visits.today > 0 ? `${overview.site_visits.today} today` : 'Next 7 days'}</p>
      </Card>
      <Card className="p-4">
        <p className="flex items-center gap-1.5 text-xs font-medium text-ink-700/60">
          <Wallet className="h-3.5 w-3.5" aria-hidden="true" /> For-Sale Portfolio Value
        </p>
        <p className="mt-1 font-display text-2xl font-bold text-ink-900">{formatNprCompact(overview.for_sale_portfolio_value.total)}</p>
        <p className="text-xs text-ink-700/60">{overview.for_sale_portfolio_value.listing_count} active sale listings</p>
      </Card>
    </div>
  )
}

function ListingsTable({
  data,
  isPending,
  isError,
  onRetry,
  page,
  setPage,
}: {
  data?: { data: import('../lib/api/agencyDashboard').AgencyListingRow[]; meta: { current_page: number; last_page: number; total: number } }
  isPending: boolean
  isError: boolean
  onRetry: () => void
  page: number
  setPage: (p: number) => void
}) {
  if (isPending) return <Skeleton className="h-96 w-full" />
  if (isError) return <ErrorState onRetry={onRetry} description="Couldn't load your listings right now." />
  if (!data || data.data.length === 0) {
    return <EmptyState title="No listings match this filter" description="Try a different category or clear your search." />
  }

  return (
    <Card className="overflow-hidden p-0">
      <div className="flex flex-col divide-y divide-stone-100">
        {data.data.map((row) => (
          <Link key={row.id} to={`/listings/${row.slug}`} className="flex items-center gap-3 p-3 hover:bg-stone-50">
            <div className="h-14 w-14 shrink-0 overflow-hidden rounded-lg bg-stone-100">
              {row.cover_image_url ? (
                <img src={row.cover_image_url} alt="" className="h-full w-full object-cover" />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-ink-700/30">
                  <HomeIcon className="h-5 w-5" aria-hidden="true" />
                </div>
              )}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium text-ink-900">{row.title}</p>
              <p className="truncate text-xs text-ink-700/60">
                {row.location?.municipality}
                {row.location?.ward_number ? `, Ward ${row.location.ward_number}` : ''} · Ref: {row.reference_code}
              </p>
            </div>
            <div className="shrink-0 text-right">
              <p className="text-sm font-semibold text-trust-700">
                {formatNprCompact(row.price)}
                {row.purpose === 'rent' && row.price_period === 'monthly' && <span className="text-xs font-normal text-ink-700/60">/mo</span>}
              </p>
              <p className="text-xs text-ink-700/60">{row.inquiries_count} inquiries · {row.leads_count} visits</p>
            </div>
          </Link>
        ))}
      </div>
      {data.meta.last_page > 1 && (
        <div className="flex items-center justify-between border-t border-stone-100 p-3 text-xs text-ink-700/60">
          <span>
            Showing page {data.meta.current_page} of {data.meta.last_page} · {data.meta.total} verified holdings
          </span>
          <div className="flex gap-2">
            <button type="button" disabled={page <= 1} onClick={() => setPage(page - 1)} className="rounded-md border border-stone-200 px-2 py-1 disabled:opacity-40">
              Previous
            </button>
            <button type="button" disabled={page >= data.meta.last_page} onClick={() => setPage(page + 1)} className="rounded-md border border-stone-200 px-2 py-1 disabled:opacity-40">
              Next
            </button>
          </div>
        </div>
      )}
    </Card>
  )
}

function InquiriesPanel({ inquiries, isPending }: { inquiries?: import('../lib/api/agencyDashboard').AgencyInquiry[]; isPending: boolean }) {
  return (
    <Card className="p-4">
      <h2 className="mb-3 flex items-center gap-1.5 font-display text-sm font-semibold text-ink-900">
        <MessageCircle className="h-4 w-4 text-trust-700" aria-hidden="true" /> Direct Buyer Inquiries
      </h2>
      {isPending && <Skeleton className="h-32 w-full" />}
      {!isPending && (!inquiries || inquiries.length === 0) && (
        <p className="text-sm text-ink-700/60">No buyer conversations yet.</p>
      )}
      {!isPending && inquiries && inquiries.length > 0 && (
        <div className="flex flex-col gap-3">
          {inquiries.map((inq) => (
            <Link key={inq.id} to="/messages" className="block rounded-lg border border-stone-200 p-3 hover:bg-stone-50">
              <div className="flex items-center justify-between gap-2">
                <p className="text-sm font-medium text-ink-900">{inq.buyer_name ?? 'A buyer'}</p>
                <span className="text-xs text-ink-700/50">{inq.message_count} message{inq.message_count === 1 ? '' : 's'}</span>
              </div>
              <p className="truncate text-xs text-ink-700/60">{inq.listing_title}</p>
            </Link>
          ))}
        </div>
      )}
      <Link to="/messages" className="mt-3 inline-block text-xs font-medium text-trust-700 hover:underline">
        View all conversations →
      </Link>
    </Card>
  )
}

function SiteVisitsPanel({ visits, isPending }: { visits?: import('../lib/api/agencyDashboard').AgencySiteVisit[]; isPending: boolean }) {
  return (
    <Card className="p-4">
      <h2 className="mb-3 flex items-center gap-1.5 font-display text-sm font-semibold text-ink-900">
        <Calendar className="h-4 w-4 text-trust-700" aria-hidden="true" /> Scheduled Site Visits
      </h2>
      {isPending && <Skeleton className="h-32 w-full" />}
      {!isPending && (!visits || visits.length === 0) && (
        <p className="text-sm text-ink-700/60">No site visits scheduled in the next 7 days.</p>
      )}
      {!isPending && visits && visits.length > 0 && (
        <div className="flex flex-col gap-3">
          {visits.map((v) => (
            <Link key={v.id} to={v.listing_slug ? `/listings/${v.listing_slug}` : '/account/viewing-requests?as=host'} className="block rounded-lg border border-stone-200 p-3 hover:bg-stone-50">
              <div className="flex items-center justify-between gap-2">
                <p className="text-xs font-semibold text-trust-700">
                  {v.when && new Date(v.when).toLocaleString(undefined, { weekday: 'short', hour: 'numeric', minute: '2-digit', month: 'short', day: 'numeric' })}
                </p>
                <Badge tone={v.is_confirmed ? 'success' : 'warning'}>{v.is_confirmed ? 'Confirmed' : 'Requested'}</Badge>
              </div>
              <p className="truncate text-sm text-ink-900">{v.listing_title}</p>
              <p className="truncate text-xs text-ink-700/60">{v.municipality} · {v.requester_name}</p>
            </Link>
          ))}
        </div>
      )}
    </Card>
  )
}

function AlertReachPanel({ overview, isPending }: { overview?: ReturnType<typeof useAgencyOverview>['data']; isPending: boolean }) {
  if (isPending || !overview) return <Skeleton className="h-24 w-full" />

  return (
    <Card className="p-4">
      <h2 className="font-display text-sm font-semibold text-ink-900">Alert Reach</h2>
      <p className="mt-2 font-display text-2xl font-bold text-ink-900">{overview.alert_reach}</p>
      <p className="text-xs text-ink-700/60">
        Buyers currently subscribed to instant/daily alerts for cities where you have active listings — a live count, not a
        delivery or open-rate estimate.
      </p>
    </Card>
  )
}

import { Link } from 'react-router-dom'
import { Building2, ClipboardList, CreditCard, LayoutDashboard, ShieldCheck, Users } from 'lucide-react'
import { useDashboardStats } from '../../lib/api/admin'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { ADMIN_TONE_BADGE, type AdminTone } from '../../components/admin/tones'
import { clsx } from 'clsx'

function StatCard({
  icon: Icon,
  label,
  value,
  sub,
  to,
  tone = 'trust',
}: {
  icon: typeof Users
  label: string
  value: number | string
  sub?: string
  to?: string
  tone?: AdminTone
}) {
  const content = (
    <Card className="flex flex-col gap-3 p-4 transition-shadow hover:shadow-md">
      <div className="flex items-center gap-2">
        <span className={clsx('flex h-8 w-8 items-center justify-center rounded-lg', ADMIN_TONE_BADGE[tone])}>
          <Icon className="h-4 w-4" aria-hidden="true" />
        </span>
        <span className="text-xs font-medium uppercase tracking-wide text-ink-700/60">{label}</span>
      </div>
      <p className="font-display text-2xl font-semibold text-ink-900">{value}</p>
      {sub && <p className="text-xs text-ink-700/60">{sub}</p>}
    </Card>
  )

  return to ? <Link to={to}>{content}</Link> : content
}

export function Dashboard() {
  const { data: stats, isPending, isError, refetch } = useDashboardStats()

  if (isPending) {
    return (
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} className="h-28 w-full" />
        ))}
      </div>
    )
  }

  if (isError || !stats) {
    return <ErrorState onRetry={refetch} description="Couldn't load dashboard stats right now." />
  }

  const moderationTotal =
    stats.moderation_queue.reports +
    stats.moderation_queue.duplicate_flags +
    stats.moderation_queue.verifications +
    stats.moderation_queue.community_notes

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={LayoutDashboard}
        title="Dashboard"
        description="Live counts, computed directly from the database."
      />

      {moderationTotal > 0 && (
        <Card className="flex flex-wrap items-center justify-between gap-3 border-warning-100 bg-warning-100/40 p-4">
          <p className="text-sm text-ink-900">
            <strong>{moderationTotal}</strong> item{moderationTotal === 1 ? '' : 's'} waiting in moderation queues.
          </p>
          <div className="flex flex-wrap gap-2 text-xs">
            {stats.moderation_queue.reports > 0 && (
              <Link to="/admin/reports" className="rounded-full bg-white px-3 py-1 font-medium text-ink-900 hover:bg-stone-100">
                {stats.moderation_queue.reports} report{stats.moderation_queue.reports === 1 ? '' : 's'}
              </Link>
            )}
            {stats.moderation_queue.duplicate_flags > 0 && (
              <Link to="/admin/duplicate-flags" className="rounded-full bg-white px-3 py-1 font-medium text-ink-900 hover:bg-stone-100">
                {stats.moderation_queue.duplicate_flags} duplicate flag{stats.moderation_queue.duplicate_flags === 1 ? '' : 's'}
              </Link>
            )}
            {stats.moderation_queue.verifications > 0 && (
              <Link to="/admin/verifications" className="rounded-full bg-white px-3 py-1 font-medium text-ink-900 hover:bg-stone-100">
                {stats.moderation_queue.verifications} verification{stats.moderation_queue.verifications === 1 ? '' : 's'}
              </Link>
            )}
            {stats.moderation_queue.community_notes > 0 && (
              <Link to="/admin/community-notes" className="rounded-full bg-white px-3 py-1 font-medium text-ink-900 hover:bg-stone-100">
                {stats.moderation_queue.community_notes} community note{stats.moderation_queue.community_notes === 1 ? '' : 's'}
              </Link>
            )}
          </div>
        </Card>
      )}

      <div>
        <h2 className="mb-3 font-display text-base font-semibold text-ink-900">Listings</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard tone="link" icon={ClipboardList} label="Total listings" value={stats.listings.total} />
          <StatCard tone="link" icon={ClipboardList} label="Published" value={stats.listings.published} />
          <StatCard
            tone="link"
            icon={ClipboardList}
            label="Pending review"
            value={stats.listings.pending_review}
            to="/admin/listings/pending"
            sub={stats.listings.pending_review > 0 ? 'Needs attention' : 'All caught up'}
          />
          <StatCard tone="link" icon={ClipboardList} label="Featured now" value={stats.listings.featured_active} />
        </div>
      </div>

      <div>
        <h2 className="mb-3 font-display text-base font-semibold text-ink-900">People</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard tone="accent" icon={Users} label="Total users" value={stats.users.total} to="/admin/users" />
          <StatCard tone="accent" icon={Users} label="Owners" value={stats.users.owners} />
          <StatCard tone="accent" icon={Users} label="Agents" value={stats.users.agents} />
          <StatCard
            tone="accent"
            icon={Users}
            label="Suspended"
            value={stats.users.suspended}
            to="/admin/users"
            sub={stats.users.suspended > 0 ? 'Review if needed' : undefined}
          />
        </div>
      </div>

      <div>
        <h2 className="mb-3 font-display text-base font-semibold text-ink-900">Agencies & payments</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard tone="success" icon={Building2} label="Total agencies" value={stats.agencies.total} to="/admin/agencies" />
          <StatCard tone="success" icon={ShieldCheck} label="Verified" value={stats.agencies.verified} to="/admin/agencies" />
          <StatCard
            tone="success"
            icon={Building2}
            label="Pending verification"
            value={stats.agencies.pending}
            to="/admin/agencies"
            sub={stats.agencies.pending > 0 ? 'Needs review' : 'All caught up'}
          />
          <StatCard
            tone="success"
            icon={CreditCard}
            label="Completed payments"
            value={formatNpr(stats.payments.completed_amount)}
            sub={`${stats.payments.completed_count} transaction${stats.payments.completed_count === 1 ? '' : 's'}`}
            to="/admin/payments"
          />
        </div>
      </div>
    </div>
  )
}

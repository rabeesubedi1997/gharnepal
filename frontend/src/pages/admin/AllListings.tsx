import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { ClipboardList, ExternalLink, Sparkles } from 'lucide-react'
import { useAdminListings } from '../../lib/api/admin'
import { formatNpr } from '../../design-system/tokens'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Select } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'
import type { ListingStatus } from '../../lib/api/listings'

const STATUS_OPTIONS: { value: string; label: string }[] = [
  { value: 'all', label: 'All statuses' },
  { value: 'draft', label: 'Draft' },
  { value: 'pending_review', label: 'Pending review' },
  { value: 'published', label: 'Published' },
  { value: 'paused', label: 'Paused' },
  { value: 'rented', label: 'Rented' },
  { value: 'sold', label: 'Sold' },
  { value: 'rejected', label: 'Rejected' },
  { value: 'expired', label: 'Expired' },
]

const STATUS_TONE: Record<ListingStatus, 'neutral' | 'warning' | 'success' | 'danger' | 'trust'> = {
  draft: 'neutral',
  pending_review: 'warning',
  published: 'success',
  paused: 'neutral',
  rented: 'trust',
  sold: 'trust',
  rejected: 'danger',
  expired: 'neutral',
}

/** The general "browse every listing regardless of status" admin view —
 * separate from /admin/listings/pending (the moderation queue, which keeps
 * its own dedicated approve/reject workflow). This one is read-only:
 * dashboard tiles like "Total listings"/"Published"/"Featured now" link
 * here with the matching filter pre-applied. */
export function AllListings() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [status, setStatus] = useState(searchParams.get('status') ?? 'all')
  const [featured, setFeatured] = useState(searchParams.get('featured') === 'true')
  const [page, setPage] = useState(1)

  const { data, isPending, isError, refetch } = useAdminListings({ status, featured, page })

  const updateFilters = (nextStatus: string, nextFeatured: boolean) => {
    setStatus(nextStatus)
    setFeatured(nextFeatured)
    setPage(1)
    setSearchParams(
      { ...(nextStatus !== 'all' && { status: nextStatus }), ...(nextFeatured && { featured: 'true' }) },
      { replace: true },
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={ClipboardList}
        tone="trust"
        title="All listings"
        description="Every listing regardless of status — for moderation, use the pending queue instead."
      />

      <div className="flex flex-wrap items-center gap-3">
        <Select value={status} onChange={(e) => updateFilters(e.target.value, featured)} className="w-48">
          {STATUS_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </Select>
        <label className="flex items-center gap-2 text-sm text-ink-900">
          <input
            type="checkbox"
            checked={featured}
            onChange={(e) => updateFilters(status, e.target.checked)}
            className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
          />
          Featured now only
        </label>
      </div>

      {isPending && <PropertyGridSkeleton count={6} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No listings match these filters" description="Try a different status." />
      )}

      <div className="flex flex-col gap-2">
        {data?.data.map((listing) => (
          <Card key={listing.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <p className="font-medium text-ink-900">{listing.title}</p>
                {listing.is_featured && (
                  <Badge tone="warning">
                    <Sparkles className="h-3 w-3" aria-hidden="true" /> Featured
                  </Badge>
                )}
              </div>
              <p className="text-xs text-ink-700/60">
                {formatNpr(listing.price)}
                {listing.price_period === 'monthly' && ' / month'} · {listing.property.property_type} ·{' '}
                {listing.poster?.name ?? 'Unknown poster'}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <Badge tone={STATUS_TONE[listing.status]}>{listing.status.replace('_', ' ')}</Badge>
              {listing.status === 'published' && (
                <a
                  href={`/listings/${listing.slug}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-xs font-medium text-trust-700 hover:underline"
                >
                  View <ExternalLink className="h-3 w-3" aria-hidden="true" />
                </a>
              )}
            </div>
          </Card>
        ))}
      </div>

      {data && data.meta.last_page > 1 && (
        <div className="flex items-center justify-center gap-3">
          <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
            Previous
          </Button>
          <span className="text-sm text-ink-700/70">
            Page {data.meta.current_page} of {data.meta.last_page}
          </span>
          <Button
            variant="outline"
            size="sm"
            disabled={page >= data.meta.last_page}
            onClick={() => setPage((p) => p + 1)}
          >
            Next
          </Button>
        </div>
      )}
    </div>
  )
}

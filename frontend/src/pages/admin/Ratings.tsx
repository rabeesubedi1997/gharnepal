import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Star } from 'lucide-react'
import { useAdminRatings, useHideRating, useUnhideRating, type AdminRating } from '../../lib/api/admin'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Select } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'
import { clsx } from 'clsx'

export function Ratings() {
  const [status, setStatus] = useState<AdminRating['status'] | ''>('')
  const { data, isPending, isError, refetch } = useAdminRatings(status || undefined)
  const hide = useHideRating()
  const unhide = useUnhideRating()

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-semibold text-ink-900">Ratings & reviews</h1>
          <p className="mt-1 text-sm text-ink-700/70">
            Reviews publish immediately — hide one here if it's abusive, spam, or off-topic.
          </p>
        </div>
        <Select value={status} onChange={(e) => setStatus(e.target.value as AdminRating['status'] | '')} className="w-40">
          <option value="">All</option>
          <option value="visible">Visible</option>
          <option value="hidden">Hidden</option>
        </Select>
      </div>

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}
      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No ratings" description="Listing ratings will show up here." />
      )}

      <div className="flex flex-col gap-2">
        {data?.data.map((rating) => (
          <Card key={rating.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
            <div>
              <div className="flex items-center gap-2">
                <span className="flex items-center">
                  {[1, 2, 3, 4, 5].map((n) => (
                    <Star key={n} className={clsx('h-3.5 w-3.5', n <= rating.score ? 'fill-warning-600 text-warning-600' : 'text-stone-300')} />
                  ))}
                </span>
                {rating.listing ? (
                  <Link to={`/listings/${rating.listing.slug}`} className="text-sm font-medium text-link-600 hover:text-link-700">
                    {rating.listing.title}
                  </Link>
                ) : (
                  <span className="text-sm font-medium text-ink-900">Listing removed</span>
                )}
              </div>
              {rating.comment && <p className="mt-1 text-sm text-ink-700/80">{rating.comment}</p>}
              <p className="mt-1 text-xs text-ink-700/60">
                {rating.user?.name ?? 'Unknown user'} · {new Date(rating.created_at).toLocaleDateString()}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <Badge tone={rating.status === 'visible' ? 'success' : 'danger'}>{rating.status}</Badge>
              {rating.status === 'visible' ? (
                <Button size="sm" variant="danger" isLoading={hide.isPending && hide.variables === rating.id} onClick={() => hide.mutate(rating.id)}>
                  Hide
                </Button>
              ) : (
                <Button size="sm" variant="outline" isLoading={unhide.isPending && unhide.variables === rating.id} onClick={() => unhide.mutate(rating.id)}>
                  Unhide
                </Button>
              )}
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}

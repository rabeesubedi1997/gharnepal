import { Link } from 'react-router-dom'
import { useConfirmDuplicateFlag, useDismissDuplicateFlag, useDuplicateFlags } from '../../lib/api/duplicateFlags'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const REASON_LABEL: Record<string, string> = {
  same_owner: 'Same owner',
  same_ward: 'Same ward',
  similar_price: 'Similar price',
  similar_area: 'Similar area',
  similar_title: 'Similar title',
}

export function DuplicateFlags() {
  const { data, isPending, isError, refetch } = useDuplicateFlags('unreviewed')
  const confirm = useConfirmDuplicateFlag()
  const dismiss = useDismissDuplicateFlag()

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-ink-700/70">
        Flagged automatically when a listing looks like it might duplicate an existing one. Never
        auto-removed — confirm to act on it, or dismiss if it's a false positive.
      </p>

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No duplicate flags" description="Possible duplicates will appear here for review." />
      )}

      {data?.data.map((flag) => (
        <Card key={flag.id} className="flex flex-col gap-3 p-4">
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div className="rounded-lg border border-stone-200 p-3">
              <p className="text-xs uppercase tracking-wide text-ink-700/50">New submission</p>
              <Link to={`/listings/${flag.listing.slug}`} className="font-medium text-link-600 hover:text-link-700">
                {flag.listing.title}
              </Link>
              <p className="text-sm text-ink-700/70">{formatNpr(flag.listing.price)}</p>
            </div>
            <div className="rounded-lg border border-stone-200 p-3">
              <p className="text-xs uppercase tracking-wide text-ink-700/50">Possible match</p>
              <Link to={`/listings/${flag.duplicate_of.slug}`} className="font-medium text-link-600 hover:text-link-700">
                {flag.duplicate_of.title}
              </Link>
              <p className="text-sm text-ink-700/70">{formatNpr(flag.duplicate_of.price)}</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex flex-wrap gap-1.5">
              <Badge tone="warning">{flag.match_score}% match</Badge>
              {flag.match_reasons.map((r) => (
                <Badge key={r} tone="neutral">{REASON_LABEL[r] ?? r}</Badge>
              ))}
            </div>
            <div className="flex gap-2">
              <Button size="sm" variant="outline" onClick={() => dismiss.mutate(flag.id)} isLoading={dismiss.isPending}>
                Dismiss
              </Button>
              <Button size="sm" onClick={() => confirm.mutate(flag.id)} isLoading={confirm.isPending}>
                Confirm duplicate
              </Button>
            </div>
          </div>
        </Card>
      ))}
    </div>
  )
}

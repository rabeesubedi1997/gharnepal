import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useAdminPayments, type PaymentStatus } from '../../lib/api/payments'
import { useRefundPayment } from '../../lib/api/admin'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Select } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const STATUS_TONE: Record<PaymentStatus, 'success' | 'warning' | 'danger' | 'neutral'> = {
  completed: 'success',
  pending: 'warning',
  failed: 'danger',
  refunded: 'neutral',
}

export function Payments() {
  const [status, setStatus] = useState<PaymentStatus | ''>('')
  const { data, isPending, isError, refetch } = useAdminPayments(status || undefined)
  const refund = useRefundPayment()

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-ink-700/70">
          Every featured-listing purchase. The only action available is a refund on a completed payment —
          nothing here is ever hand-edited.
        </p>
        <Select value={status} onChange={(e) => setStatus(e.target.value as PaymentStatus | '')} className="w-44">
          <option value="">All statuses</option>
          <option value="pending">Pending</option>
          <option value="completed">Completed</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </Select>
      </div>

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No transactions" description="Featured-listing purchases will show up here." />
      )}

      {data?.data.map((tx) => (
        <Card key={tx.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
          <div>
            {tx.listing ? (
              <Link to={`/listings/${tx.listing.slug}`} className="font-medium text-link-600 hover:text-link-700">
                {tx.listing.title}
              </Link>
            ) : (
              <span className="font-medium text-ink-900">Listing removed</span>
            )}
            <p className="text-xs text-ink-700/60">
              {tx.user?.name ?? 'Unknown user'} · {tx.plan_days}-day boost · {new Date(tx.created_at).toLocaleDateString()}
            </p>
            <p className="font-mono text-xs text-ink-700/50">{tx.gateway_reference}</p>
          </div>
          <div className="flex items-center gap-2">
            <span className="font-semibold text-ink-900">{formatNpr(tx.amount)}</span>
            <Badge tone={STATUS_TONE[tx.status]}>{tx.status}</Badge>
            {tx.status === 'completed' && (
              <Button
                size="sm"
                variant="outline"
                isLoading={refund.isPending && refund.variables === tx.id}
                onClick={() => refund.mutate(tx.id)}
              >
                Refund
              </Button>
            )}
          </div>
        </Card>
      ))}
    </div>
  )
}

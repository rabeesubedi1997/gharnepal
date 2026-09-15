import { Link, useSearchParams } from 'react-router-dom'
import { Receipt } from 'lucide-react'
import { useOwnerPayments, type PaymentStatus } from '../../lib/api/payments'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const STATUS_TONE: Record<PaymentStatus, 'success' | 'warning' | 'danger' | 'neutral'> = {
  completed: 'success',
  pending: 'warning',
  failed: 'danger',
  refunded: 'neutral',
}

const CALLBACK_BANNER: Record<string, { tone: 'success' | 'danger' | 'warning'; text: string }> = {
  success: { tone: 'success', text: 'Payment received — your boost is now active.' },
  failed: { tone: 'danger', text: 'That payment did not go through — no charge was made. You can try again below.' },
  not_found: { tone: 'warning', text: "We couldn't match that payment to a transaction — contact support if you were charged." },
}

export function PaymentHistory() {
  const { data, isPending, isError, refetch } = useOwnerPayments()
  const [searchParams] = useSearchParams()
  const banner = CALLBACK_BANNER[searchParams.get('status') ?? '']

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6">
      <div className="flex items-center gap-2">
        <Receipt className="h-6 w-6 text-trust-700" aria-hidden="true" />
        <h1 className="font-display text-2xl font-semibold text-ink-900">Payment history</h1>
      </div>

      {banner && (
        <div
          className={`rounded-lg p-3 text-sm ${
            banner.tone === 'success'
              ? 'bg-success-100/40 text-success-700'
              : banner.tone === 'danger'
                ? 'bg-danger-100/40 text-danger-700'
                : 'bg-warning-100/40 text-warning-700'
          }`}
        >
          {banner.text}
        </div>
      )}

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState
          title="No payments yet"
          description="Boost a listing to feature it in search — purchases will show up here as a receipt."
        />
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
              {tx.plan_days}-day boost · {new Date(tx.created_at).toLocaleDateString()} · ref {tx.gateway_reference}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className="font-semibold text-ink-900">{formatNpr(tx.amount)}</span>
            <Badge tone={STATUS_TONE[tx.status]}>{tx.status}</Badge>
          </div>
        </Card>
      ))}
    </div>
  )
}

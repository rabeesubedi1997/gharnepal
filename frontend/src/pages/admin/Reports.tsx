import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Flag } from 'lucide-react'
import { useAdminReports, useResolveReport, type ListingReport } from '../../lib/api/reports'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const REASON_LABEL: Record<string, string> = {
  fraud: 'Fraud',
  duplicate: 'Duplicate listing',
  sold_already: 'Already sold/rented',
  misleading: 'Misleading',
  inappropriate: 'Inappropriate',
  other: 'Other',
}

export function Reports() {
  const { data, isPending, isError, refetch } = useAdminReports('open')
  const resolve = useResolveReport()
  const [acting, setActing] = useState<{ report: ListingReport; status: 'dismissed' | 'action_taken' } | null>(null)
  const [note, setNote] = useState('')

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader icon={Flag} tone="warning" title="Reports" description="Open reports on listings, waiting for a decision." />

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No open reports" description="Reported listings will show up here for review." />
      )}

      {data?.data.map((report) => (
        <Card key={report.id} className="flex flex-col gap-2 p-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <Link to={`/listings/${report.listing.slug}`} className="font-medium text-link-600 hover:text-link-700">
              {report.listing.title}
            </Link>
            <Badge tone="danger">{REASON_LABEL[report.reason] ?? report.reason}</Badge>
          </div>
          {report.details && <p className="text-sm text-ink-700/80">{report.details}</p>}
          <p className="text-xs text-ink-700/60">
            Reported by {report.reported_by?.name ?? 'a user'} on {new Date(report.created_at).toLocaleDateString()}
          </p>
          <div className="mt-2 flex gap-2">
            <Button size="sm" variant="outline" onClick={() => { setActing({ report, status: 'dismissed' }); setNote('') }}>
              Dismiss
            </Button>
            <Button size="sm" variant="danger" onClick={() => { setActing({ report, status: 'action_taken' }); setNote('') }}>
              Take action
            </Button>
          </div>
        </Card>
      ))}

      <Modal open={!!acting} onClose={() => setActing(null)} title={acting?.status === 'dismissed' ? 'Dismiss report' : 'Mark action taken'}>
        <div className="flex flex-col gap-3">
          <textarea
            rows={3}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Resolution note (optional)"
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
          <Button
            isLoading={resolve.isPending}
            onClick={() =>
              acting &&
              resolve.mutate(
                { id: acting.report.id, status: acting.status, resolution_note: note || undefined },
                { onSuccess: () => setActing(null) },
              )
            }
          >
            Confirm
          </Button>
        </div>
      </Modal>
    </div>
  )
}

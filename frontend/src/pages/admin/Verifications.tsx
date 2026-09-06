import { useState } from 'react'
import { useAdminVerifications, useApproveVerification, useRejectVerification, type UserVerification } from '../../lib/api/verifications'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const TYPE_LABEL: Record<string, string> = {
  identity: 'Identity document',
  agent_license: 'Agent license',
  agency_document: 'Agency document',
}

export function Verifications() {
  const { data, isPending, isError, refetch } = useAdminVerifications('pending')
  const approve = useApproveVerification()
  const reject = useRejectVerification()
  const [rejecting, setRejecting] = useState<UserVerification | null>(null)
  const [reason, setReason] = useState('')

  return (
    <div className="flex flex-col gap-4">
      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No pending verifications" description="Submitted identity and agent documents will show up here." />
      )}

      {data?.data.map((v) => (
        <Card key={v.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
          <div className="flex items-center gap-3">
            {v.document_url && (
              <a href={v.document_url} target="_blank" rel="noreferrer">
                <img src={v.document_url} alt="Submitted document" className="h-16 w-16 rounded-lg border border-stone-200 object-cover" />
              </a>
            )}
            <div>
              <p className="font-medium text-ink-900">{v.user?.name}</p>
              <p className="text-xs text-ink-700/60">{v.user?.email}</p>
              <Badge tone="neutral">{TYPE_LABEL[v.type] ?? v.type}</Badge>
            </div>
          </div>
          <div className="flex gap-2">
            <Button size="sm" variant="outline" onClick={() => { setRejecting(v); setReason('') }}>
              Reject
            </Button>
            <Button size="sm" onClick={() => approve.mutate(v.id)} isLoading={approve.isPending}>
              Approve
            </Button>
          </div>
        </Card>
      ))}

      <Modal open={!!rejecting} onClose={() => setRejecting(null)} title="Reject verification">
        <div className="flex flex-col gap-3">
          <textarea
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Why is this being rejected?"
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
          <Button
            isLoading={reject.isPending}
            disabled={!reason.trim()}
            onClick={() => rejecting && reject.mutate({ id: rejecting.id, reason }, { onSuccess: () => setRejecting(null) })}
          >
            Confirm rejection
          </Button>
        </div>
      </Modal>
    </div>
  )
}

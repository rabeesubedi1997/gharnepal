import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  COMMUNITY_NOTE_CATEGORY_LABEL,
  useAdminCommunityNotes,
  useApproveCommunityNote,
  useRejectCommunityNote,
  type CommunityNote,
} from '../../lib/api/neighborhoods'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { Tabs } from '../../components/ui/Tabs'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const STATUS_TABS = [
  { key: 'pending', label: 'Pending' },
  { key: 'approved', label: 'Approved' },
  { key: 'rejected', label: 'Rejected' },
]

export function CommunityNotesModeration() {
  const [status, setStatus] = useState<'pending' | 'approved' | 'rejected'>('pending')
  const { data, isPending, isError, refetch } = useAdminCommunityNotes(status)
  const approve = useApproveCommunityNote()
  const reject = useRejectCommunityNote()
  const [rejecting, setRejecting] = useState<CommunityNote | null>(null)
  const [reason, setReason] = useState('')

  return (
    <div className="flex flex-col gap-4">
      <Tabs tabs={STATUS_TABS} active={status} onChange={(key) => setStatus(key as typeof status)} />

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title={`No ${status} notes`} description="Community notes will show up here for review." />
      )}

      {data?.data.map((note) => (
        <Card key={note.id} className="flex flex-col gap-2 p-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            {note.neighborhood ? (
              <Link to={`/neighborhoods/${note.neighborhood.id}`} className="font-medium text-link-600 hover:text-link-700">
                {note.neighborhood.name}
              </Link>
            ) : (
              <span className="font-medium text-ink-900">Unknown neighborhood</span>
            )}
            <Badge tone="neutral">{COMMUNITY_NOTE_CATEGORY_LABEL[note.category]}</Badge>
          </div>
          <p className="text-sm text-ink-700/80">{note.body}</p>
          <p className="text-xs text-ink-700/60">
            Submitted by {note.submitted_by?.name ?? 'a verified user'} on {new Date(note.created_at).toLocaleDateString()}
          </p>
          {note.rejection_reason && <p className="text-xs text-danger-600">Rejected: {note.rejection_reason}</p>}
          {status === 'pending' && (
            <div className="mt-2 flex gap-2">
              <Button size="sm" variant="outline" onClick={() => { setRejecting(note); setReason('') }}>
                Reject
              </Button>
              <Button size="sm" isLoading={approve.isPending} onClick={() => approve.mutate(note.id)}>
                Approve
              </Button>
            </div>
          )}
        </Card>
      ))}

      <Modal open={!!rejecting} onClose={() => setRejecting(null)} title="Reject community note">
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

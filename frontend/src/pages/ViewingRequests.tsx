import { useState } from 'react'
import { CalendarCheck } from 'lucide-react'
import {
  useSubmitVisitVerification,
  useTransitionViewing,
  useViewingRequests,
  type ViewingRequest,
  type ViewingStatus,
} from '../lib/api/viewingRequests'
import { Card } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Tabs } from '../components/ui/Tabs'
import { Modal } from '../components/ui/Modal'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'

const STATUS_TONE: Record<ViewingStatus, 'neutral' | 'warning' | 'success' | 'danger' | 'trust'> = {
  requested: 'warning',
  confirmed: 'success',
  rescheduled: 'warning',
  completed: 'trust',
  cancelled: 'danger',
  no_show: 'danger',
}

export function ViewingRequests() {
  const [as, setAs] = useState<'requester' | 'host'>('requester')
  const { data, isPending, isError, refetch } = useViewingRequests(as)
  const transition = useTransitionViewing()
  const [verifying, setVerifying] = useState<ViewingRequest | null>(null)

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-display text-2xl font-semibold text-ink-900">Viewing requests</h1>

      <Tabs
        tabs={[
          { key: 'requester', label: 'My requests' },
          { key: 'host', label: 'Requests for my listings' },
        ]}
        active={as}
        onChange={(k) => setAs(k as 'requester' | 'host')}
      />

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.length === 0 && (
        <EmptyState
          icon={<CalendarCheck className="h-10 w-10" aria-hidden="true" />}
          title={as === 'requester' ? 'No viewing requests yet' : 'No one has requested a viewing yet'}
          description={as === 'requester' ? 'Request a viewing from any listing page.' : 'Requests for your listings will show up here.'}
        />
      )}

      <div className="flex flex-col gap-3">
        {data?.map((v) => (
          <Card key={v.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
            <div>
              <p className="font-medium text-ink-900">{v.listing.title}</p>
              <p className="text-sm text-ink-700/70">
                {as === 'requester' ? `Host: ${v.host?.name}` : `Requested by: ${v.requester?.name}`}
              </p>
              <p className="text-xs text-ink-700/60">
                {new Date(v.confirmed_datetime ?? v.proposed_datetime).toLocaleString(undefined, {
                  dateStyle: 'medium',
                  timeStyle: 'short',
                })}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <Badge tone={STATUS_TONE[v.status]}>{v.status.replace('_', ' ')}</Badge>

              {as === 'host' && v.status === 'requested' && (
                <Button size="sm" onClick={() => transition.mutate({ id: v.id, action: 'confirm' })} isLoading={transition.isPending}>
                  Confirm
                </Button>
              )}
              {as === 'host' && v.status === 'confirmed' && (
                <Button size="sm" onClick={() => transition.mutate({ id: v.id, action: 'complete' })} isLoading={transition.isPending}>
                  Mark completed
                </Button>
              )}
              {['requested', 'confirmed', 'rescheduled'].includes(v.status) && (
                <Button size="sm" variant="outline" onClick={() => transition.mutate({ id: v.id, action: 'cancel' })}>
                  Cancel
                </Button>
              )}
              {as === 'requester' && v.status === 'completed' && !v.visit_verification && (
                <Button size="sm" variant="outline" onClick={() => setVerifying(v)}>
                  Rate this visit
                </Button>
              )}
              {v.visit_verification && <Badge tone="success">Visit verified</Badge>}
            </div>
          </Card>
        ))}
      </div>

      <VisitVerificationModal viewing={verifying} onClose={() => setVerifying(null)} />
    </div>
  )
}

function VisitVerificationModal({ viewing, onClose }: { viewing: ViewingRequest | null; onClose: () => void }) {
  const submit = useSubmitVisitVerification()
  const [form, setForm] = useState({ matched_listing: true, price_accurate: true, host_attended: true, overall_comment: '' })

  if (!viewing) return null

  return (
    <Modal open onClose={onClose} title="How did the visit go?">
      <div className="flex flex-col gap-3">
        <Checkbox label="The property matched the listing" checked={form.matched_listing} onChange={(v) => setForm({ ...form, matched_listing: v })} />
        <Checkbox label="The price was accurate" checked={form.price_accurate} onChange={(v) => setForm({ ...form, price_accurate: v })} />
        <Checkbox label="The owner or agent attended" checked={form.host_attended} onChange={(v) => setForm({ ...form, host_attended: v })} />
        <textarea
          rows={3}
          placeholder="Any other comments (optional)"
          value={form.overall_comment}
          onChange={(e) => setForm({ ...form, overall_comment: e.target.value })}
          className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
        <Button
          isLoading={submit.isPending}
          onClick={() =>
            submit.mutate(
              { id: viewing.id, visited: true, ...form },
              { onSuccess: onClose },
            )
          }
        >
          Submit feedback
        </Button>
      </div>
    </Modal>
  )
}

function Checkbox({ label, checked, onChange }: { label: string; checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <label className="flex items-center gap-2 text-sm text-ink-900">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
      />
      {label}
    </label>
  )
}

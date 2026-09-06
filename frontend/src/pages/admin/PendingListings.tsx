import { useState } from 'react'
import { useApproveListing, usePendingListings, useRejectListing } from '../../lib/api/admin'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'
import { getErrorMessage } from '../../lib/api/errors'

export function PendingListings() {
  const { data, isPending, isError, refetch } = usePendingListings('pending_review')
  const approve = useApproveListing()
  const reject = useRejectListing()
  const [rejecting, setRejecting] = useState<number | null>(null)
  const [reason, setReason] = useState('')
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-display text-2xl font-semibold text-ink-900">Listing approval queue</h1>

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="Nothing to review" description="New submissions will show up here." />
      )}

      <div className="flex flex-col gap-4">
        {data?.data.map((listing) => (
          <Card key={listing.id} className="flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex gap-3">
              {listing.property.media[0] && (
                <img src={listing.property.media[0].url} alt="" className="h-16 w-24 rounded-lg object-cover" />
              )}
              <div>
                <p className="font-medium text-ink-900">{listing.title}</p>
                <p className="text-sm text-ink-700/70">
                  {formatNpr(listing.price)} · {listing.property.property_type}
                  {listing.property.address?.municipality && ` · ${listing.property.address.municipality.name}`}
                </p>
              </div>
            </div>
            <div className="flex gap-2">
              <Button
                size="sm"
                variant="outline"
                onClick={() => {
                  setRejecting(listing.id)
                  setReason('')
                  setError(null)
                }}
              >
                Reject
              </Button>
              <Button
                size="sm"
                isLoading={approve.isPending && approve.variables === listing.id}
                onClick={() => approve.mutate(listing.id)}
              >
                Approve
              </Button>
            </div>
          </Card>
        ))}
      </div>

      <Modal open={rejecting !== null} onClose={() => setRejecting(null)} title="Reject listing">
        <div className="flex flex-col gap-3">
          <label className="text-sm font-medium text-ink-900" htmlFor="reject-reason">
            Reason (shown to the poster)
          </label>
          <textarea
            id="reject-reason"
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
          {error && <p className="text-sm text-danger-600">{error}</p>}
          <Button
            isLoading={reject.isPending}
            disabled={!reason.trim()}
            onClick={() =>
              reject.mutate(
                { listingId: rejecting!, reason },
                {
                  onSuccess: () => setRejecting(null),
                  onError: (e) => setError(getErrorMessage(e)),
                },
              )
            }
          >
            Confirm rejection
          </Button>
        </div>
      </Modal>
    </div>
  )
}

import { useState } from 'react'
import { CheckCircle2, ShieldAlert, Sparkles, XCircle } from 'lucide-react'
import { useConfirmPayment, useFeaturedPlans, usePurchaseFeature, type PaymentTransaction } from '../../lib/api/payments'
import { getErrorMessage } from '../../lib/api/errors'
import { formatNpr } from '../../design-system/tokens'
import { Modal } from '../ui/Modal'
import { Button } from '../ui/Button'
import { Card } from '../ui/Card'
import { Skeleton } from '../ui/Skeleton'

type Step = 'select' | 'checkout' | 'result'

export function FeatureListingModal({
  open,
  onClose,
  listingId,
  listingTitle,
}: {
  open: boolean
  onClose: () => void
  listingId: number
  listingTitle: string
}) {
  const { data: plans, isPending: plansPending } = useFeaturedPlans()
  const purchase = usePurchaseFeature()
  const confirm = useConfirmPayment()

  const [step, setStep] = useState<Step>('select')
  const [transaction, setTransaction] = useState<PaymentTransaction | null>(null)
  const [error, setError] = useState<string | null>(null)

  const reset = () => {
    setStep('select')
    setTransaction(null)
    setError(null)
  }

  const handleClose = () => {
    reset()
    onClose()
  }

  const handleSelectPlan = (planKey: string) => {
    setError(null)
    purchase.mutate(
      { listingId, planKey },
      {
        onSuccess: (tx) => {
          setTransaction(tx)
          setStep('checkout')
        },
        onError: (err) => setError(getErrorMessage(err)),
      },
    )
  }

  const handleConfirm = (outcome: 'success' | 'failure') => {
    if (!transaction) return
    setError(null)
    confirm.mutate(
      { transactionId: transaction.id, outcome },
      {
        onSuccess: (tx) => {
          setTransaction(tx)
          setStep('result')
        },
        onError: (err) => setError(getErrorMessage(err)),
      },
    )
  }

  return (
    <Modal open={open} onClose={handleClose} title="Feature this listing">
      {step === 'select' && (
        <div className="flex flex-col gap-3">
          <p className="text-sm text-ink-700/70">
            Boosted listings show a "Featured" badge and appear more prominently in search. Choose a boost length
            for <span className="font-medium text-ink-900">{listingTitle}</span>.
          </p>
          {plansPending && <Skeleton className="h-32 w-full" />}
          {error && <p className="text-sm text-danger-600">{error}</p>}
          <div className="flex flex-col gap-2">
            {plans?.map((plan) => (
              <Card
                key={plan.key}
                role="button"
                tabIndex={0}
                onClick={() => !purchase.isPending && handleSelectPlan(plan.key)}
                onKeyDown={(e) => e.key === 'Enter' && handleSelectPlan(plan.key)}
                className="flex cursor-pointer items-center justify-between gap-3 p-3 transition-shadow hover:shadow-md"
              >
                <div>
                  <p className="font-medium text-ink-900">{plan.label}</p>
                  <p className="text-xs text-ink-700/60">{plan.days} days of featured placement</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-trust-700">{formatNpr(plan.price)}</span>
                  {purchase.isPending && purchase.variables?.planKey === plan.key && (
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-trust-700 border-t-transparent" />
                  )}
                </div>
              </Card>
            ))}
          </div>
        </div>
      )}

      {step === 'checkout' && transaction && (
        <div className="flex flex-col gap-4">
          <div className="rounded-lg border border-dashed border-accent-600/50 bg-accent-100/30 p-3 text-center">
            <p className="text-xs font-semibold uppercase tracking-wide text-accent-600">Sandbox payment · test mode</p>
            <p className="mt-1 text-xs text-ink-700/70">
              No real payment gateway is connected in this environment — no money moves. This screen simulates the
              outcome an eSewa/Khalti checkout would return.
            </p>
          </div>
          <Card className="flex flex-col gap-2 p-4">
            <div className="flex justify-between text-sm">
              <span className="text-ink-700/60">Amount</span>
              <span className="font-semibold text-ink-900">{formatNpr(transaction.amount)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-ink-700/60">Plan</span>
              <span className="text-ink-900">{transaction.plan_days} days</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-ink-700/60">Reference</span>
              <span className="font-mono text-xs text-ink-900">{transaction.gateway_reference}</span>
            </div>
          </Card>
          {error && <p className="text-sm text-danger-600">{error}</p>}
          <div className="flex gap-2">
            <Button className="flex-1" isLoading={confirm.isPending && confirm.variables?.outcome === 'success'} onClick={() => handleConfirm('success')}>
              Simulate successful payment
            </Button>
            <Button
              variant="outline"
              className="flex-1"
              isLoading={confirm.isPending && confirm.variables?.outcome === 'failure'}
              onClick={() => handleConfirm('failure')}
            >
              Simulate failed payment
            </Button>
          </div>
        </div>
      )}

      {step === 'result' && transaction && (
        <div className="flex flex-col items-center gap-3 py-4 text-center">
          {transaction.status === 'completed' ? (
            <>
              <CheckCircle2 className="h-10 w-10 text-success-600" aria-hidden="true" />
              <p className="font-medium text-ink-900">
                <Sparkles className="mb-0.5 mr-1 inline h-4 w-4 text-accent-600" />
                Listing is now featured
                {transaction.listing?.featured_until && ` until ${new Date(transaction.listing.featured_until).toLocaleDateString()}`}.
              </p>
            </>
          ) : (
            <>
              <XCircle className="h-10 w-10 text-danger-600" aria-hidden="true" />
              <p className="font-medium text-ink-900">Payment failed — no charge was made.</p>
              <p className="flex items-center gap-1 text-xs text-ink-700/60">
                <ShieldAlert className="h-3.5 w-3.5" /> You can try again any time from your dashboard.
              </p>
            </>
          )}
          <Button size="sm" onClick={handleClose}>
            Done
          </Button>
        </div>
      )}
    </Modal>
  )
}

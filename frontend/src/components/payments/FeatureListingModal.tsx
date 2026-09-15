import { useRef, useState } from 'react'
import { CheckCircle2, ShieldAlert, Sparkles, XCircle } from 'lucide-react'
import {
  useConfirmPayment,
  useFeaturedPlans,
  usePaymentGatewayOptions,
  usePurchaseFeature,
  type PaymentGatewayOption,
  type PaymentTransaction,
} from '../../lib/api/payments'
import { getErrorMessage } from '../../lib/api/errors'
import { formatNpr } from '../../design-system/tokens'
import { Modal } from '../ui/Modal'
import { Button } from '../ui/Button'
import { Card } from '../ui/Card'
import { Skeleton } from '../ui/Skeleton'

type Step = 'select' | 'gateway' | 'checkout' | 'redirecting' | 'result'

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
  const { data: gateways, isPending: gatewaysPending } = usePaymentGatewayOptions()
  const purchase = usePurchaseFeature()
  const confirm = useConfirmPayment()
  const formRef = useRef<HTMLFormElement>(null)

  const [step, setStep] = useState<Step>('select')
  const [planKey, setPlanKey] = useState<string | null>(null)
  const [gateway, setGateway] = useState<PaymentGatewayOption | null>(null)
  const [transaction, setTransaction] = useState<PaymentTransaction | null>(null)
  const [formAction, setFormAction] = useState<{ url: string; fields: Record<string, string> } | null>(null)
  const [instructions, setInstructions] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const reset = () => {
    setStep('select')
    setPlanKey(null)
    setGateway(null)
    setTransaction(null)
    setFormAction(null)
    setInstructions(null)
    setError(null)
  }

  const handleClose = () => {
    reset()
    onClose()
  }

  const handleSelectPlan = (key: string) => {
    setPlanKey(key)
    setStep('gateway')
  }

  const handleSelectGateway = (option: PaymentGatewayOption) => {
    if (!planKey) return
    setError(null)
    setGateway(option)
    purchase.mutate(
      { listingId, planKey, gatewayConfigId: option.id },
      {
        onSuccess: ({ data: tx, checkout }) => {
          setTransaction(tx)
          if (checkout.mode === 'redirect' && checkout.redirect_url) {
            setStep('redirecting')
            window.location.href = checkout.redirect_url
          } else if (checkout.mode === 'form_post' && checkout.redirect_url) {
            setFormAction({ url: checkout.redirect_url, fields: checkout.form_fields })
            setStep('redirecting')
            // Submitted via the hidden <form> rendered below, once state applies.
            requestAnimationFrame(() => formRef.current?.submit())
          } else {
            setInstructions(checkout.instructions)
            setStep('checkout')
          }
        },
        onError: (err) => {
          setError(getErrorMessage(err))
          setStep('gateway')
        },
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
          <div className="flex flex-col gap-2">
            {plans?.map((plan) => (
              <Card
                key={plan.key}
                role="button"
                tabIndex={0}
                onClick={() => handleSelectPlan(plan.key)}
                onKeyDown={(e) => e.key === 'Enter' && handleSelectPlan(plan.key)}
                className="flex cursor-pointer items-center justify-between gap-3 p-3 transition-shadow hover:shadow-md"
              >
                <div>
                  <p className="font-medium text-ink-900">{plan.label}</p>
                  <p className="text-xs text-ink-700/60">{plan.days} days of featured placement</p>
                </div>
                <span className="font-semibold text-trust-700">{formatNpr(plan.price)}</span>
              </Card>
            ))}
          </div>
        </div>
      )}

      {step === 'gateway' && (
        <div className="flex flex-col gap-3">
          <p className="text-sm text-ink-700/70">How would you like to pay?</p>
          {gatewaysPending && <Skeleton className="h-24 w-full" />}
          {error && <p className="text-sm text-danger-600">{error}</p>}
          {!gatewaysPending && gateways?.length === 0 && (
            <p className="text-sm text-danger-600">No payment method is currently available. Please try again later.</p>
          )}
          <div className="flex flex-col gap-2">
            {gateways?.map((option) => (
              <Card
                key={option.id}
                role="button"
                tabIndex={0}
                onClick={() => !purchase.isPending && handleSelectGateway(option)}
                onKeyDown={(e) => e.key === 'Enter' && handleSelectGateway(option)}
                className="flex cursor-pointer items-center justify-between gap-3 p-3 transition-shadow hover:shadow-md"
              >
                <div>
                  <p className="font-medium text-ink-900">{option.label}</p>
                  {option.is_sandbox && <p className="text-xs text-accent-600">Test mode</p>}
                </div>
                {purchase.isPending && gateway?.id === option.id && (
                  <span className="h-4 w-4 animate-spin rounded-full border-2 border-trust-700 border-t-transparent" />
                )}
              </Card>
            ))}
          </div>
          <Button variant="outline" size="sm" className="self-start" onClick={() => setStep('select')}>
            Back
          </Button>
        </div>
      )}

      {step === 'redirecting' && (
        <div className="flex flex-col items-center gap-3 py-6 text-center">
          <span className="h-8 w-8 animate-spin rounded-full border-2 border-trust-700 border-t-transparent" />
          <p className="text-sm text-ink-700/70">Taking you to {gateway?.label} to complete your payment…</p>
          {formAction && (
            <form ref={formRef} method="POST" action={formAction.url} className="hidden">
              {Object.entries(formAction.fields).map(([key, value]) => (
                <input key={key} type="hidden" name={key} value={value} />
              ))}
            </form>
          )}
        </div>
      )}

      {step === 'checkout' && transaction && (
        <div className="flex flex-col gap-4">
          {gateway?.provider === 'sandbox' ? (
            <div className="rounded-lg border border-dashed border-accent-600/50 bg-accent-100/30 p-3 text-center">
              <p className="text-xs font-semibold uppercase tracking-wide text-accent-600">Sandbox payment · test mode</p>
              <p className="mt-1 text-xs text-ink-700/70">
                No real payment gateway is connected — no money moves. This screen simulates the outcome a real
                checkout would return.
              </p>
            </div>
          ) : (
            <div className="rounded-lg border border-stone-200 bg-stone-50 p-3">
              <p className="text-xs font-semibold uppercase tracking-wide text-ink-700/60">Payment instructions</p>
              <p className="mt-1 whitespace-pre-line text-sm text-ink-900">
                {instructions || 'Contact the site owner for payment details.'}
              </p>
            </div>
          )}
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
          {gateway?.provider === 'sandbox' ? (
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
          ) : (
            <p className="text-xs text-ink-700/60">
              This boost activates as soon as the site owner confirms your payment arrived — check your payment
              history for updates.
            </p>
          )}
          <Button variant="outline" size="sm" onClick={handleClose}>
            Done for now
          </Button>
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

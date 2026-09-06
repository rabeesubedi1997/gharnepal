import { CheckCircle2 } from 'lucide-react'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'
import { formatNpr } from '../../design-system/tokens'
import type { BasicsState, PricingState } from './types'

interface Props {
  basics: BasicsState
  pricing: PricingState
  onBack: () => void
  onSubmitForReview: () => void
  onSaveAsDraft: () => void
  isSubmitting: boolean
}

export function ReviewStep({ basics, pricing, onBack, onSubmitForReview, onSaveAsDraft, isSubmitting }: Props) {
  return (
    <div className="flex flex-col gap-4">
      <Card className="flex flex-col gap-3 p-5">
        <h3 className="font-display text-lg font-semibold text-ink-900">{pricing.title || 'Untitled listing'}</h3>
        <p className="text-xl font-semibold text-trust-700">
          {formatNpr(Number(pricing.price) || 0)}
          {pricing.purpose === 'rent' && pricing.price_period === 'monthly' && ' / month'}
        </p>
        <dl className="grid grid-cols-2 gap-2 text-sm text-ink-700/80 sm:grid-cols-3">
          <Row label="Type" value={basics.property_type} />
          <Row label="Area" value={`${basics.area_value} ${basics.area_unit}`} />
          {basics.bedrooms && <Row label="Bedrooms" value={basics.bedrooms} />}
          {basics.bathrooms && <Row label="Bathrooms" value={basics.bathrooms} />}
          <Row label="Purpose" value={pricing.purpose === 'sale' ? 'For sale' : 'For rent'} />
          <Row label="Amenities" value={`${pricing.amenity_ids.length} selected`} />
        </dl>
        {pricing.description && <p className="text-sm text-ink-700/80">{pricing.description}</p>}
      </Card>

      <div className="flex items-start gap-2 rounded-card bg-trust-100 p-4 text-sm text-trust-700">
        <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
        <p>
          Submitting for review sends this listing to our moderation team. It will go live once
          approved — usually within a day. You can keep editing it as a draft instead if you're
          not ready yet.
        </p>
      </div>

      <div className="mt-2 flex flex-wrap justify-between gap-2">
        <Button variant="outline" onClick={onBack} type="button">
          Back
        </Button>
        <div className="flex gap-2">
          <Button variant="ghost" onClick={onSaveAsDraft} type="button" disabled={isSubmitting}>
            Save as draft
          </Button>
          <Button onClick={onSubmitForReview} isLoading={isSubmitting}>
            Submit for review
          </Button>
        </div>
      </div>
    </div>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs uppercase tracking-wide text-ink-700/50">{label}</dt>
      <dd className="font-medium text-ink-900">{value}</dd>
    </div>
  )
}

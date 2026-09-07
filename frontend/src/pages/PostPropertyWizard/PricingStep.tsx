import { useAmenities } from '../../lib/api/amenities'
import { Input, Select } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { Skeleton } from '../../components/ui/Skeleton'
import type { PricingState } from './types'

interface Props {
  value: PricingState
  onChange: (value: PricingState) => void
  errors: Partial<Record<keyof PricingState, string>>
  onNext: () => void
  onBack: () => void
  isSubmitting: boolean
}

export function PricingStep({ value, onChange, errors, onNext, onBack, isSubmitting }: Props) {
  const { data: amenities, isPending } = useAmenities()

  const toggleAmenity = (id: number) => {
    const set = new Set(value.amenity_ids)
    if (set.has(id)) set.delete(id)
    else set.add(id)
    onChange({ ...value, amenity_ids: Array.from(set) })
  }

  return (
    <div className="flex flex-col gap-4">
      <Input
        label="Listing title"
        placeholder="e.g. Sunny 2BHK apartment near Boudha"
        value={value.title}
        error={errors.title}
        onChange={(e) => onChange({ ...value, title: e.target.value })}
      />

      <div className="grid grid-cols-2 gap-4">
        <Select
          label="Purpose"
          value={value.purpose}
          error={errors.purpose}
          onChange={(e) => onChange({ ...value, purpose: e.target.value as PricingState['purpose'] })}
        >
          <option value="">Select</option>
          <option value="sale">For sale</option>
          <option value="rent">For rent</option>
        </Select>
        <Input
          label="Price (NPR)"
          type="number"
          min="1"
          placeholder="e.g. 5000000"
          value={value.price}
          error={errors.price}
          onChange={(e) => onChange({ ...value, price: e.target.value })}
        />
      </div>

      {value.purpose === 'rent' && (
        <Select
          label="Price period"
          value={value.price_period}
          error={errors.price_period}
          onChange={(e) => onChange({ ...value, price_period: e.target.value as PricingState['price_period'] })}
        >
          <option value="">Select</option>
          <option value="monthly">Per month</option>
          <option value="total">Total</option>
        </Select>
      )}

      <label className="flex items-center gap-2 text-sm text-ink-900">
        <input
          type="checkbox"
          checked={value.negotiable}
          onChange={(e) => onChange({ ...value, negotiable: e.target.checked })}
          className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
        />
        Price is negotiable
      </label>

      <Input
        label="Available from (optional)"
        type="date"
        value={value.availability_date}
        onChange={(e) => onChange({ ...value, availability_date: e.target.value })}
      />

      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-medium text-ink-900">Description</label>
        <textarea
          rows={5}
          value={value.description}
          onChange={(e) => onChange({ ...value, description: e.target.value })}
          className="rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700"
          placeholder="Describe the property, nearby amenities, and anything buyers should know."
        />
      </div>

      <div>
        <p className="mb-2 text-sm font-medium text-ink-900">Amenities</p>
        {isPending ? (
          <Skeleton className="h-24 w-full" />
        ) : (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {amenities?.map((amenity) => (
              <label
                key={amenity.id}
                className="flex items-center gap-2 rounded-lg border border-stone-200 px-3 py-2 text-sm text-ink-900 hover:bg-stone-100"
              >
                <input
                  type="checkbox"
                  checked={value.amenity_ids.includes(amenity.id)}
                  onChange={() => toggleAmenity(amenity.id)}
                  className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
                />
                {amenity.name}
              </label>
            ))}
          </div>
        )}
      </div>

      <div className="mt-2 flex justify-between">
        <Button variant="outline" onClick={onBack} type="button">
          Back
        </Button>
        <Button onClick={onNext} isLoading={isSubmitting}>
          Review listing
        </Button>
      </div>
    </div>
  )
}

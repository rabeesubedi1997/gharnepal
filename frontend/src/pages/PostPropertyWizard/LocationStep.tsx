import { AddressFields } from '../../components/property/AddressFields'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import type { AddressState } from './types'

interface Props {
  value: AddressState
  onChange: (value: AddressState) => void
  errors: Partial<Record<string, string>>
  onNext: () => void
  onBack: () => void
  isSubmitting: boolean
}

export function LocationStep({ value, onChange, errors, onNext, onBack, isSubmitting }: Props) {
  return (
    <div className="flex flex-col gap-4">
      <AddressFields
        value={value}
        errors={errors}
        onChange={(addr) => onChange({ ...value, ...addr })}
      />
      <Input
        label="Street address (optional)"
        value={value.street_address}
        onChange={(e) => onChange({ ...value, street_address: e.target.value })}
      />
      <Input
        label="Nearby landmark (optional)"
        value={value.landmark}
        onChange={(e) => onChange({ ...value, landmark: e.target.value })}
      />

      <div className="mt-2 flex justify-between">
        <Button variant="outline" onClick={onBack} type="button">
          Back
        </Button>
        <Button onClick={onNext} isLoading={isSubmitting}>
          Save & continue to photos
        </Button>
      </div>
    </div>
  )
}

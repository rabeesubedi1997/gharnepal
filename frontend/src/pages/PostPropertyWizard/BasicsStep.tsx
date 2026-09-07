import type { AreaUnit } from '../../lib/api/properties'
import { Input, Select } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { type BasicsState, RESIDENTIAL_TYPES } from './types'

const AREA_UNITS: { value: AreaUnit; label: string }[] = [
  { value: 'sqft', label: 'sq ft' },
  { value: 'sqm', label: 'sq m' },
  { value: 'aana', label: 'Aana' },
  { value: 'ropani', label: 'Ropani' },
  { value: 'kattha', label: 'Kattha' },
  { value: 'dhur', label: 'Dhur' },
]

interface Props {
  value: BasicsState
  onChange: (value: BasicsState) => void
  errors: Partial<Record<keyof BasicsState, string>>
  onNext: () => void
}

export function BasicsStep({ value, onChange, errors, onNext }: Props) {
  const isResidential = RESIDENTIAL_TYPES.includes(value.property_type as never)

  return (
    <div className="flex flex-col gap-4">
      <Select
        label="Property type"
        value={value.property_type}
        error={errors.property_type}
        onChange={(e) => onChange({ ...value, property_type: e.target.value as BasicsState['property_type'] })}
      >
        <option value="">Select type</option>
        <option value="room">Room</option>
        <option value="apartment">Apartment / Flat</option>
        <option value="house">House</option>
        <option value="land">Land</option>
        <option value="commercial">Commercial</option>
      </Select>

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Area"
          type="number"
          min="0"
          step="0.01"
          placeholder="e.g. 1200"
          value={value.area_value}
          error={errors.area_value}
          onChange={(e) => onChange({ ...value, area_value: e.target.value })}
        />
        <Select
          label="Unit"
          value={value.area_unit}
          onChange={(e) => onChange({ ...value, area_unit: e.target.value as AreaUnit })}
        >
          {AREA_UNITS.map((u) => (
            <option key={u.value} value={u.value}>{u.label}</option>
          ))}
        </Select>
      </div>

      {isResidential && (
        <div className="grid grid-cols-2 gap-4">
          <Input
            label="Bedrooms"
            type="number"
            min="0"
            placeholder="e.g. 3"
            value={value.bedrooms}
            error={errors.bedrooms}
            onChange={(e) => onChange({ ...value, bedrooms: e.target.value })}
          />
          <Input
            label="Bathrooms"
            type="number"
            min="0"
            placeholder="e.g. 2"
            value={value.bathrooms}
            error={errors.bathrooms}
            onChange={(e) => onChange({ ...value, bathrooms: e.target.value })}
          />
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Floors (optional)"
          type="number"
          min="0"
          placeholder="e.g. 2"
          value={value.floors}
          onChange={(e) => onChange({ ...value, floors: e.target.value })}
        />
        <Input
          label="Year built (optional)"
          type="number"
          placeholder="e.g. 2018"
          value={value.year_built}
          onChange={(e) => onChange({ ...value, year_built: e.target.value })}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <Input
          label="Parking spaces"
          type="number"
          min="0"
          placeholder="e.g. 1"
          value={value.parking_spaces}
          onChange={(e) => {
            const spaces = e.target.value
            // Clearing the count back to empty/0 clears the type too, so we
            // never persist a "bike parking" claim for a listing with 0 spaces.
            const shouldClearType = !spaces || Number(spaces) === 0
            onChange({ ...value, parking_spaces: spaces, parking_type: shouldClearType ? '' : value.parking_type })
          }}
        />
        <Select
          label="Parking type"
          value={value.parking_type}
          disabled={!value.parking_spaces || Number(value.parking_spaces) === 0}
          onChange={(e) => onChange({ ...value, parking_type: e.target.value as BasicsState['parking_type'] })}
        >
          <option value="">Select</option>
          <option value="car">Car</option>
          <option value="bike">Bike / scooter</option>
          <option value="both">Car & bike</option>
        </Select>
      </div>

      {isResidential && (
        <Select
          label="Furnished status"
          value={value.is_furnished}
          onChange={(e) => onChange({ ...value, is_furnished: e.target.value as BasicsState['is_furnished'] })}
        >
          <option value="">Select</option>
          <option value="unfurnished">Unfurnished</option>
          <option value="semi">Semi-furnished</option>
          <option value="full">Fully furnished</option>
        </Select>
      )}

      <div className="mt-2 flex justify-end">
        <Button onClick={onNext}>Continue to location</Button>
      </div>
    </div>
  )
}

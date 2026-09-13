import { Plus, X } from 'lucide-react'
import type { AreaUnit } from '../../lib/api/properties'
import { Input, Select } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { type BasicsState, RESIDENTIAL_TYPES, STRUCTURAL_DETAIL_TYPES } from './types'

const FACING_DIRECTIONS: { value: string; label: string }[] = [
  { value: '', label: 'Not specified' },
  { value: 'north', label: 'North' },
  { value: 'south', label: 'South' },
  { value: 'east', label: 'East' },
  { value: 'west', label: 'West' },
  { value: 'northeast', label: 'Northeast' },
  { value: 'northwest', label: 'Northwest' },
  { value: 'southeast', label: 'Southeast' },
  { value: 'southwest', label: 'Southwest' },
]

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
  const showStructuralDetails = STRUCTURAL_DETAIL_TYPES.includes(value.property_type as never)

  const addFloor = () => {
    onChange({
      ...value,
      floor_breakdown: [...value.floor_breakdown, { label: `Floor ${value.floor_breakdown.length + 1}`, area_sqft: '', description: '' }],
    })
  }
  const updateFloor = (index: number, patch: Partial<BasicsState['floor_breakdown'][number]>) => {
    onChange({
      ...value,
      floor_breakdown: value.floor_breakdown.map((row, i) => (i === index ? { ...row, ...patch } : row)),
    })
  }
  const removeFloor = (index: number) => {
    onChange({ ...value, floor_breakdown: value.floor_breakdown.filter((_, i) => i !== index) })
  }

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

      {showStructuralDetails && (
        <>
          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Facing direction (optional)"
              value={value.facing_direction}
              onChange={(e) => onChange({ ...value, facing_direction: e.target.value as BasicsState['facing_direction'] })}
            >
              {FACING_DIRECTIONS.map((d) => (
                <option key={d.value} value={d.value}>{d.label}</option>
              ))}
            </Select>
            <Input
              label="Water tank capacity, liters (optional)"
              type="number"
              min="0"
              placeholder="e.g. 15000"
              value={value.water_tank_capacity_liters}
              onChange={(e) => onChange({ ...value, water_tank_capacity_liters: e.target.value })}
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium text-ink-900">Structural notes (optional)</label>
            <textarea
              rows={2}
              value={value.structural_notes}
              onChange={(e) => onChange({ ...value, structural_notes: e.target.value })}
              className="rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700"
              placeholder="e.g. 14x14 inch RCC columns, NBC 105:2020 seismic compliant"
            />
          </div>

          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <label className="text-sm font-medium text-ink-900">Floor-by-floor breakdown (optional)</label>
              <button type="button" onClick={addFloor} className="inline-flex items-center gap-1 text-xs font-medium text-trust-700 hover:underline">
                <Plus className="h-3.5 w-3.5" /> Add floor
              </button>
            </div>
            {value.floor_breakdown.map((row, i) => (
              <div key={i} className="flex flex-col gap-2 rounded-lg border border-stone-200 p-3">
                <div className="flex items-start gap-2">
                  <div className="grid flex-1 grid-cols-2 gap-2">
                    <Input
                      label="Level name"
                      value={row.label}
                      onChange={(e) => updateFloor(i, { label: e.target.value })}
                    />
                    <Input
                      label="Area, sq ft"
                      type="number"
                      min="0"
                      value={row.area_sqft}
                      onChange={(e) => updateFloor(i, { area_sqft: e.target.value })}
                    />
                  </div>
                  <button
                    type="button"
                    onClick={() => removeFloor(i)}
                    aria-label="Remove floor"
                    className="mt-6 rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
                <textarea
                  rows={2}
                  value={row.description}
                  onChange={(e) => updateFloor(i, { description: e.target.value })}
                  className="rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700"
                  placeholder="What's on this level"
                />
              </div>
            ))}
          </div>
        </>
      )}

      <div className="mt-2 flex justify-end">
        <Button onClick={onNext}>Continue to location</Button>
      </div>
    </div>
  )
}

import { Input, Select } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import type { LandProfileInput } from '../../lib/api/landProfile'

interface Props {
  value: LandProfileInput
  onChange: (value: LandProfileInput) => void
  onNext: () => void
  onBack: () => void
  isSubmitting: boolean
}

export function LandDetailsStep({ value, onChange, onNext, onBack, isSubmitting }: Props) {
  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-ink-700/70">
        This becomes the land due-diligence checklist buyers see on your listing. Fill in what
        you know now — you can update it later.
      </p>

      <Input label="Kitta number (optional)" value={value.kitta_number ?? ''} onChange={(e) => onChange({ ...value, kitta_number: e.target.value })} />

      <Select
        label="Lalpurja (ownership certificate) available?"
        value={value.lalpurja_available ?? 'unknown'}
        onChange={(e) => onChange({ ...value, lalpurja_available: e.target.value as LandProfileInput['lalpurja_available'] })}
      >
        <option value="unknown">Not sure yet</option>
        <option value="yes">Yes</option>
        <option value="in_process">In process</option>
        <option value="no">No</option>
      </Select>

      <div className="grid grid-cols-2 gap-4">
        <label className="flex items-center gap-2 text-sm text-ink-900">
          <input
            type="checkbox"
            checked={value.road_access ?? false}
            onChange={(e) => onChange({ ...value, road_access: e.target.checked })}
            className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
          />
          Has road access
        </label>
        <Select label="Road type" value={value.road_type ?? 'none'} onChange={(e) => onChange({ ...value, road_type: e.target.value as LandProfileInput['road_type'] })}>
          <option value="none">None</option>
          <option value="dirt">Dirt</option>
          <option value="gravel">Gravel</option>
          <option value="blacktop">Blacktop</option>
        </Select>
      </div>

      <Input
        label="Road width in meters (optional)"
        type="number"
        min="0"
        step="0.5"
        value={value.road_width_meters ?? ''}
        onChange={(e) => onChange({ ...value, road_width_meters: e.target.value ? Number(e.target.value) : null })}
      />

      <div className="grid grid-cols-2 gap-4">
        <Select label="Water access" value={value.water_access ?? 'unknown'} onChange={(e) => onChange({ ...value, water_access: e.target.value as LandProfileInput['water_access'] })}>
          <option value="unknown">Not sure</option>
          <option value="municipal">Municipal supply</option>
          <option value="well">Well / borehole</option>
          <option value="none">None</option>
        </Select>
        <Select label="Drainage" value={value.drainage_access ?? 'unknown'} onChange={(e) => onChange({ ...value, drainage_access: e.target.value as LandProfileInput['drainage_access'] })}>
          <option value="unknown">Not sure</option>
          <option value="yes">Yes</option>
          <option value="no">No</option>
        </Select>
      </div>

      <label className="flex items-center gap-2 text-sm text-ink-900">
        <input
          type="checkbox"
          checked={value.electricity_access ?? false}
          onChange={(e) => onChange({ ...value, electricity_access: e.target.checked })}
          className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
        />
        Has electricity access
      </label>

      <Select
        label="Land classification"
        value={value.land_classification ?? 'residential'}
        onChange={(e) => onChange({ ...value, land_classification: e.target.value as LandProfileInput['land_classification'] })}
      >
        <option value="residential">Residential</option>
        <option value="agricultural">Agricultural</option>
        <option value="commercial">Commercial</option>
        <option value="guthi">Guthi</option>
        <option value="other">Other</option>
      </Select>

      <div className="grid grid-cols-2 gap-4">
        <Select label="Flood risk" value={value.flood_risk ?? 'unknown'} onChange={(e) => onChange({ ...value, flood_risk: e.target.value as LandProfileInput['flood_risk'] })}>
          <option value="unknown">Not sure</option>
          <option value="none">None</option>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </Select>
        <Select label="Landslide risk" value={value.landslide_risk ?? 'unknown'} onChange={(e) => onChange({ ...value, landslide_risk: e.target.value as LandProfileInput['landslide_risk'] })}>
          <option value="unknown">Not sure</option>
          <option value="none">None</option>
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </Select>
      </div>

      <div className="flex flex-col gap-1.5">
        <label className="text-sm font-medium text-ink-900">Nearby development (optional)</label>
        <textarea
          rows={3}
          value={value.nearby_development_notes ?? ''}
          onChange={(e) => onChange({ ...value, nearby_development_notes: e.target.value })}
          placeholder="e.g. New road planned nearby, upcoming housing project, etc."
          className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
      </div>

      <div className="mt-2 flex justify-between">
        <Button variant="outline" onClick={onBack} type="button">Back</Button>
        <Button onClick={onNext} isLoading={isSubmitting}>Save & continue to photos</Button>
      </div>
    </div>
  )
}

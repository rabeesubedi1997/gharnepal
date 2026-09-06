import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sparkles } from 'lucide-react'
import {
  LIFESTYLE_TAGS,
  LIFESTYLE_TAG_LABEL,
  useMatchPreferences,
  useSaveMatchPreferences,
  type LifestyleTag,
  type MatchPreferencesInput,
} from '../../lib/api/matching'
import { useMunicipalities } from '../../lib/api/locations'
import { getErrorMessage } from '../../lib/api/errors'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { Input, Select } from '../../components/ui/Input'
import { Skeleton } from '../../components/ui/Skeleton'
import { WorkLocationPicker } from '../../components/matching/WorkLocationPicker'

type FormState = {
  purpose: '' | 'sale' | 'rent'
  property_type: '' | 'room' | 'apartment' | 'house' | 'land' | 'commercial'
  budget_min: string
  budget_max: string
  min_bedrooms: string
  preferred_municipality_id: string
  work_lat: number | null
  work_lng: number | null
  work_location_label: string
  commute_limit_minutes: string
  family_size: string
  requires_school_nearby: boolean
  requires_parking: boolean
  investment_purpose: boolean
  lifestyle_tags: LifestyleTag[]
}

const initial: FormState = {
  purpose: '',
  property_type: '',
  budget_min: '',
  budget_max: '',
  min_bedrooms: '',
  preferred_municipality_id: '',
  work_lat: null,
  work_lng: null,
  work_location_label: '',
  commute_limit_minutes: '',
  family_size: '',
  requires_school_nearby: false,
  requires_parking: false,
  investment_purpose: false,
  lifestyle_tags: [],
}

export function MatchPreferences() {
  const { data: prefs, isPending } = useMatchPreferences()
  const { data: municipalities } = useMunicipalities()
  const save = useSaveMatchPreferences()
  const navigate = useNavigate()

  const [form, setForm] = useState<FormState>(initial)
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    if (!prefs) return
    setForm({
      purpose: prefs.purpose ?? '',
      property_type: prefs.property_type ?? '',
      budget_min: prefs.budget_min?.toString() ?? '',
      budget_max: prefs.budget_max?.toString() ?? '',
      min_bedrooms: prefs.min_bedrooms?.toString() ?? '',
      preferred_municipality_id: prefs.preferred_municipality_id?.toString() ?? '',
      work_lat: prefs.work_lat,
      work_lng: prefs.work_lng,
      work_location_label: prefs.work_location_label ?? '',
      commute_limit_minutes: prefs.commute_limit_minutes?.toString() ?? '',
      family_size: prefs.family_size?.toString() ?? '',
      requires_school_nearby: prefs.requires_school_nearby,
      requires_parking: prefs.requires_parking,
      investment_purpose: prefs.investment_purpose,
      lifestyle_tags: prefs.lifestyle_tags,
    })
  }, [prefs])

  const toggleTag = (tag: LifestyleTag) => {
    setForm((f) => ({
      ...f,
      lifestyle_tags: f.lifestyle_tags.includes(tag) ? f.lifestyle_tags.filter((t) => t !== tag) : [...f.lifestyle_tags, tag],
    }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setSaved(false)

    const input: MatchPreferencesInput = {
      purpose: form.purpose || undefined,
      property_type: form.property_type || undefined,
      budget_min: form.budget_min ? Number(form.budget_min) : undefined,
      budget_max: form.budget_max ? Number(form.budget_max) : undefined,
      min_bedrooms: form.min_bedrooms ? Number(form.min_bedrooms) : undefined,
      preferred_municipality_id: form.preferred_municipality_id ? Number(form.preferred_municipality_id) : undefined,
      work_lat: form.work_lat ?? undefined,
      work_lng: form.work_lng ?? undefined,
      work_location_label: form.work_location_label || undefined,
      commute_limit_minutes: form.commute_limit_minutes ? Number(form.commute_limit_minutes) : undefined,
      family_size: form.family_size ? Number(form.family_size) : undefined,
      requires_school_nearby: form.requires_school_nearby,
      requires_parking: form.requires_parking,
      investment_purpose: form.investment_purpose,
      lifestyle_tags: form.lifestyle_tags,
    }

    save.mutate(input, {
      onSuccess: () => {
        setSaved(true)
        navigate('/account/match-results')
      },
      onError: (err) => setError(getErrorMessage(err)),
    })
  }

  if (isPending) {
    return (
      <div className="mx-auto max-w-2xl">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="mt-4 h-96 w-full" />
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-2xl">
      <div className="mb-6 flex items-center gap-2">
        <Sparkles className="h-6 w-6 text-trust-700" aria-hidden="true" />
        <h1 className="font-display text-2xl font-semibold text-ink-900">Smart Match preferences</h1>
      </div>
      <p className="mb-6 text-sm text-ink-700/70">
        Tell us what matters and we'll rank published listings against it with a plain-language reason for every
        point — set only what's relevant, unset preferences are simply left out of scoring.
      </p>

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <Card className="flex flex-col gap-4 p-4">
          <h2 className="font-display text-base font-semibold text-ink-900">Looking for</h2>
          <div className="grid grid-cols-2 gap-3">
            <Select label="Purpose" value={form.purpose} onChange={(e) => setForm({ ...form, purpose: e.target.value as FormState['purpose'] })}>
              <option value="">Any</option>
              <option value="rent">Rent</option>
              <option value="sale">Buy</option>
            </Select>
            <Select
              label="Property type"
              value={form.property_type}
              onChange={(e) => setForm({ ...form, property_type: e.target.value as FormState['property_type'] })}
            >
              <option value="">Any</option>
              <option value="room">Room</option>
              <option value="apartment">Apartment</option>
              <option value="house">House</option>
              <option value="land">Land</option>
              <option value="commercial">Commercial</option>
            </Select>
            <Input label="Min budget (NPR)" type="number" min="0" value={form.budget_min} onChange={(e) => setForm({ ...form, budget_min: e.target.value })} />
            <Input label="Max budget (NPR)" type="number" min="0" value={form.budget_max} onChange={(e) => setForm({ ...form, budget_max: e.target.value })} />
            <Input label="Min bedrooms" type="number" min="0" max="20" value={form.min_bedrooms} onChange={(e) => setForm({ ...form, min_bedrooms: e.target.value })} />
            <Input label="Family size" type="number" min="1" max="20" value={form.family_size} onChange={(e) => setForm({ ...form, family_size: e.target.value })} />
          </div>
          <Select
            label="Preferred city"
            value={form.preferred_municipality_id}
            onChange={(e) => setForm({ ...form, preferred_municipality_id: e.target.value })}
          >
            <option value="">Any MVP city</option>
            {municipalities?.map((m) => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </Select>
        </Card>

        <Card className="flex flex-col gap-4 p-4">
          <h2 className="font-display text-base font-semibold text-ink-900">Commute</h2>
          <p className="text-xs text-ink-700/60">
            Click the map to drop a pin where you work or study — we'll estimate straight-line commute time from
            there (not a routed/traffic-aware estimate).
          </p>
          <Input
            label="Work location label (optional)"
            placeholder="e.g. Durbar Marg office"
            value={form.work_location_label}
            onChange={(e) => setForm({ ...form, work_location_label: e.target.value })}
          />
          <WorkLocationPicker
            lat={form.work_lat}
            lng={form.work_lng}
            onChange={(lat, lng) => setForm({ ...form, work_lat: lat, work_lng: lng })}
          />
          <Input
            label="Max commute (minutes)"
            type="number"
            min="5"
            max="180"
            value={form.commute_limit_minutes}
            onChange={(e) => setForm({ ...form, commute_limit_minutes: e.target.value })}
          />
        </Card>

        <Card className="flex flex-col gap-3 p-4">
          <h2 className="font-display text-base font-semibold text-ink-900">Must-haves</h2>
          <label className="flex items-center gap-2 text-sm text-ink-900">
            <input
              type="checkbox"
              checked={form.requires_school_nearby}
              onChange={(e) => setForm({ ...form, requires_school_nearby: e.target.checked })}
              className="h-4 w-4 rounded border-stone-300 text-trust-700 focus:ring-trust-700"
            />
            A school nearby (curated in the neighborhood)
          </label>
          <label className="flex items-center gap-2 text-sm text-ink-900">
            <input
              type="checkbox"
              checked={form.requires_parking}
              onChange={(e) => setForm({ ...form, requires_parking: e.target.checked })}
              className="h-4 w-4 rounded border-stone-300 text-trust-700 focus:ring-trust-700"
            />
            Parking space
          </label>
          <label className="flex items-center gap-2 text-sm text-ink-900">
            <input
              type="checkbox"
              checked={form.investment_purpose}
              onChange={(e) => setForm({ ...form, investment_purpose: e.target.checked })}
              className="h-4 w-4 rounded border-stone-300 text-trust-700 focus:ring-trust-700"
            />
            I'm buying for investment (weigh rental demand)
          </label>
        </Card>

        <Card className="flex flex-col gap-3 p-4">
          <h2 className="font-display text-base font-semibold text-ink-900">Lifestyle fit</h2>
          <p className="text-xs text-ink-700/60">Each tag is scored from real admin-curated neighborhood factors.</p>
          <div className="flex flex-wrap gap-2">
            {LIFESTYLE_TAGS.map((tag) => (
              <button
                key={tag}
                type="button"
                onClick={() => toggleTag(tag)}
                className={
                  form.lifestyle_tags.includes(tag)
                    ? 'rounded-full bg-trust-700 px-3 py-1.5 text-xs font-medium text-white'
                    : 'rounded-full border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-ink-700 hover:bg-stone-100'
                }
              >
                {LIFESTYLE_TAG_LABEL[tag]}
              </button>
            ))}
          </div>
        </Card>

        {error && <p className="text-sm text-danger-600">{error}</p>}
        {saved && <p className="text-sm text-success-600">Saved — computing your matches…</p>}
        <Button type="submit" size="lg" isLoading={save.isPending}>
          Save & find matches
        </Button>
      </form>
    </div>
  )
}

import { useMunicipalities } from '../../lib/api/locations'
import { Input, Select } from '../../components/ui/Input'
import type { SearchFilters } from '../../lib/api/listings'

interface Props {
  filters: SearchFilters
  onChange: (filters: SearchFilters) => void
}

export function FilterPanel({ filters, onChange }: Props) {
  const { data: municipalities } = useMunicipalities()

  return (
    <div className="flex flex-col gap-4">
      <Select
        label="Purpose"
        value={filters.purpose ?? ''}
        onChange={(e) => onChange({ ...filters, purpose: (e.target.value || undefined) as SearchFilters['purpose'] })}
      >
        <option value="">Buy or rent</option>
        <option value="sale">Buy</option>
        <option value="rent">Rent</option>
      </Select>

      <Select
        label="Property type"
        value={filters.property_type ?? ''}
        onChange={(e) => onChange({ ...filters, property_type: (e.target.value || undefined) as SearchFilters['property_type'] })}
      >
        <option value="">Any type</option>
        <option value="room">Room</option>
        <option value="apartment">Apartment / Flat</option>
        <option value="house">House</option>
        <option value="land">Land</option>
        <option value="commercial">Commercial</option>
      </Select>

      <Select
        label="City"
        value={filters.municipality_id ?? ''}
        onChange={(e) => onChange({ ...filters, municipality_id: e.target.value ? Number(e.target.value) : undefined })}
      >
        <option value="">All cities</option>
        {municipalities?.map((m) => (
          <option key={m.id} value={m.id}>{m.name}</option>
        ))}
      </Select>

      <div className="grid grid-cols-2 gap-3">
        <Input
          label="Min price"
          type="number"
          min="0"
          value={filters.min_price ?? ''}
          onChange={(e) => onChange({ ...filters, min_price: e.target.value ? Number(e.target.value) : undefined })}
        />
        <Input
          label="Max price"
          type="number"
          min="0"
          value={filters.max_price ?? ''}
          onChange={(e) => onChange({ ...filters, max_price: e.target.value ? Number(e.target.value) : undefined })}
        />
      </div>

      <Select
        label="Bedrooms (min)"
        value={filters.bedrooms_min ?? ''}
        onChange={(e) => onChange({ ...filters, bedrooms_min: e.target.value ? Number(e.target.value) : undefined })}
      >
        <option value="">Any</option>
        {[1, 2, 3, 4, 5].map((n) => (
          <option key={n} value={n}>{n}+</option>
        ))}
      </Select>

      <Select
        label="Sort by"
        value={filters.sort ?? 'newest'}
        onChange={(e) => onChange({ ...filters, sort: e.target.value as SearchFilters['sort'] })}
      >
        <option value="newest">Newest</option>
        <option value="price_asc">Price: low to high</option>
        <option value="price_desc">Price: high to low</option>
      </Select>

      {filters.property_type === 'land' && (
        <div className="flex flex-col gap-4 rounded-lg border border-dashed border-stone-200 p-3">
          <p className="text-xs font-medium uppercase tracking-wide text-ink-700/50">Land due-diligence</p>
          <Select
            label="Lalpurja available"
            value={filters.lalpurja_available ?? ''}
            onChange={(e) => onChange({ ...filters, lalpurja_available: (e.target.value || undefined) as SearchFilters['lalpurja_available'] })}
          >
            <option value="">Any</option>
            <option value="yes">Yes</option>
            <option value="in_process">In process</option>
            <option value="no">No</option>
          </Select>
          <label className="flex items-center gap-2 text-sm text-ink-900">
            <input
              type="checkbox"
              checked={!!filters.road_access}
              onChange={(e) => onChange({ ...filters, road_access: e.target.checked || undefined })}
              className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
            />
            Has road access
          </label>
        </div>
      )}
    </div>
  )
}

import type { SearchFilters } from './api/listings'

const NUMBER_KEYS: (keyof SearchFilters)[] = [
  'min_price', 'max_price', 'bedrooms_min', 'province_id', 'district_id', 'municipality_id', 'ward_id', 'neighborhood_id', 'page',
]

// Stored as a single comma-joined value in the shareable browser URL (e.g.
// ?amenity_ids=3,7,9) rather than repeated keys — simpler to read/write here;
// the actual API request (searchListings) sends the real number[] straight
// through axios, a separate serialization path from this one.
const ARRAY_NUMBER_KEYS: (keyof SearchFilters)[] = ['amenity_ids']

export function filtersFromSearchParams(params: URLSearchParams): SearchFilters {
  const filters: SearchFilters = {}
  for (const [key, value] of params.entries()) {
    if (!value) continue
    if (ARRAY_NUMBER_KEYS.includes(key as keyof SearchFilters)) {
      ;(filters as Record<string, unknown>)[key] = value
        .split(',')
        .map(Number)
        .filter((n) => !Number.isNaN(n))
    } else if (NUMBER_KEYS.includes(key as keyof SearchFilters)) {
      ;(filters as Record<string, unknown>)[key] = Number(value)
    } else {
      ;(filters as Record<string, unknown>)[key] = value
    }
  }
  return filters
}

export function filtersToSearchParams(filters: SearchFilters): URLSearchParams {
  const params = new URLSearchParams()
  for (const [key, value] of Object.entries(filters)) {
    if (value === undefined || value === null || value === '') continue
    if (Array.isArray(value)) {
      if (value.length === 0) continue
      params.set(key, value.join(','))
      continue
    }
    params.set(key, String(value))
  }
  return params
}

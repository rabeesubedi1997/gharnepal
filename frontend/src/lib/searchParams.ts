import type { SearchFilters } from './api/listings'

const NUMBER_KEYS: (keyof SearchFilters)[] = [
  'min_price', 'max_price', 'bedrooms_min', 'province_id', 'district_id', 'municipality_id', 'ward_id', 'neighborhood_id', 'page',
]

export function filtersFromSearchParams(params: URLSearchParams): SearchFilters {
  const filters: SearchFilters = {}
  for (const [key, value] of params.entries()) {
    if (!value) continue
    if (NUMBER_KEYS.includes(key as keyof SearchFilters)) {
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
    params.set(key, String(value))
  }
  return params
}

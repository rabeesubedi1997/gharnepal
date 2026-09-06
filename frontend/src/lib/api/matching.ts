import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { ListingPurpose, ListingSummary } from './listings'
import type { PropertyType } from './properties'

export const LIFESTYLE_TAGS = [
  'quiet',
  'safe',
  'family_friendly',
  'well_connected',
  'low_flood_risk',
  'good_internet',
  'vibrant_markets',
] as const
export type LifestyleTag = (typeof LIFESTYLE_TAGS)[number]

export const LIFESTYLE_TAG_LABEL: Record<LifestyleTag, string> = {
  quiet: 'Quiet',
  safe: 'Safe',
  family_friendly: 'Family-friendly',
  well_connected: 'Well-connected transport',
  low_flood_risk: 'Low flood risk',
  good_internet: 'Good internet',
  vibrant_markets: 'Vibrant markets',
}

export interface MatchPreferences {
  id: number | null
  purpose: ListingPurpose | null
  property_type: PropertyType | null
  budget_min: number | null
  budget_max: number | null
  min_bedrooms: number | null
  preferred_municipality_id: number | null
  preferred_municipality: string | null
  work_lat: number | null
  work_lng: number | null
  work_location_label: string | null
  commute_limit_minutes: number | null
  family_size: number | null
  requires_school_nearby: boolean
  requires_parking: boolean
  investment_purpose: boolean
  lifestyle_tags: LifestyleTag[]
  updated_at: string | null
}

export interface MatchPreferencesInput {
  purpose?: ListingPurpose
  property_type?: PropertyType
  budget_min?: number
  budget_max?: number
  min_bedrooms?: number
  preferred_municipality_id?: number
  work_lat?: number
  work_lng?: number
  work_location_label?: string
  commute_limit_minutes?: number
  family_size?: number
  requires_school_nearby?: boolean
  requires_parking?: boolean
  investment_purpose?: boolean
  lifestyle_tags?: LifestyleTag[]
}

export interface MatchReason {
  label: string
  points: number
  max_points: number
  explanation: string
}

export interface MatchResult {
  id: number
  score: number
  reasons: MatchReason[]
  computed_at: string
  listing: ListingSummary
}

export function useMatchPreferences() {
  return useQuery({
    queryKey: ['match-preferences'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: MatchPreferences }>('/account/match-preferences')
      return data.data
    },
  })
}

export function useSaveMatchPreferences() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: MatchPreferencesInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: MatchPreferences }>('/account/match-preferences', input)
      return data.data
    },
    onSuccess: (data) => {
      queryClient.setQueryData(['match-preferences'], data)
      queryClient.invalidateQueries({ queryKey: ['match-results'] })
    },
  })
}

export function useMatchResults() {
  return useQuery({
    queryKey: ['match-results'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: MatchResult[] }>('/account/match-results')
      return data.data
    },
  })
}

export function useRefreshMatchResults() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: MatchResult[] }>('/account/match-results/refresh')
      return data.data
    },
    onSuccess: (data) => queryClient.setQueryData(['match-results'], data),
  })
}

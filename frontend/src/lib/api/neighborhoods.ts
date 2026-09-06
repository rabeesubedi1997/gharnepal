import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export const NEIGHBORHOOD_SCORE_FACTORS = [
  'transport_access',
  'schools',
  'hospitals',
  'markets',
  'internet_availability',
  'road_quality',
  'noise',
  'safety',
  'flood_risk',
  'rental_demand',
  'development_activity',
] as const

export type NeighborhoodScoreFactorKey = (typeof NEIGHBORHOOD_SCORE_FACTORS)[number]

export const NEIGHBORHOOD_SCORE_FACTOR_LABEL: Record<NeighborhoodScoreFactorKey, string> = {
  transport_access: 'Transport access',
  schools: 'Schools',
  hospitals: 'Hospitals',
  markets: 'Markets',
  internet_availability: 'Internet availability',
  road_quality: 'Road quality',
  noise: 'Noise',
  safety: 'Safety',
  flood_risk: 'Flood risk',
  rental_demand: 'Rental demand',
  development_activity: 'Development activity',
}

export const POI_TYPES = ['school', 'hospital', 'market', 'transport_stop', 'bank', 'other'] as const
export type PoiType = (typeof POI_TYPES)[number]

export const POI_TYPE_LABEL: Record<PoiType, string> = {
  school: 'School',
  hospital: 'Hospital',
  market: 'Market',
  transport_stop: 'Transport stop',
  bank: 'Bank',
  other: 'Other',
}

export const COMMUNITY_NOTE_CATEGORIES = [
  'water_supply',
  'power_interruption',
  'road_condition',
  'isp_quality',
  'parking_difficulty',
  'seasonal_flooding',
  'noise',
  'market_access',
  'other',
] as const
export type CommunityNoteCategory = (typeof COMMUNITY_NOTE_CATEGORIES)[number]

export const COMMUNITY_NOTE_CATEGORY_LABEL: Record<CommunityNoteCategory, string> = {
  water_supply: 'Water supply',
  power_interruption: 'Power interruption',
  road_condition: 'Road condition',
  isp_quality: 'Internet quality',
  parking_difficulty: 'Parking difficulty',
  seasonal_flooding: 'Seasonal flooding',
  noise: 'Noise',
  market_access: 'Market access',
  other: 'Other',
}

export interface NeighborhoodScoreFactor {
  key: string
  score: number
  notes: string | null
}

export interface NeighborhoodScore {
  overall_score: number
  source: 'admin_curated' | 'blended'
  computed_at: string
  factors: NeighborhoodScoreFactor[]
}

export interface NeighborhoodPoi {
  id: number
  poi_type: PoiType
  name: string
  lat: number | null
  lng: number | null
}

export interface CommunityNote {
  id: number
  neighborhood_id: number
  category: CommunityNoteCategory
  body: string
  status: 'pending' | 'approved' | 'rejected' | 'flagged_removed'
  rejection_reason: string | null
  submitted_by?: { name: string } | null
  neighborhood?: { id: number; name: string } | null
  created_at: string
}

export interface NeighborhoodSummary {
  id: number
  name: string
  name_ne: string | null
  is_curated: boolean
  ward: { id: number; ward_number: number; municipality: string | null } | null
  score: NeighborhoodScore | null
}

export interface NeighborhoodProfile extends NeighborhoodSummary {
  pois: NeighborhoodPoi[]
  community_notes: CommunityNote[]
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useNeighborhoodList() {
  return useQuery({
    queryKey: ['neighborhoods'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: NeighborhoodSummary[] }>('/neighborhoods')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

export function useNeighborhoodProfile(id: number | string | undefined) {
  return useQuery({
    queryKey: ['neighborhoods', 'detail', id],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: NeighborhoodProfile }>(`/neighborhoods/${id}`)
      return data.data
    },
    enabled: id !== undefined,
  })
}

export function useSubmitCommunityNote() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ neighborhoodId, category, body }: { neighborhoodId: number; category: CommunityNoteCategory; body: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: CommunityNote }>(`/neighborhoods/${neighborhoodId}/community-notes`, { category, body })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['neighborhoods', 'detail', variables.neighborhoodId] })
    },
  })
}

export function useAdminSetNeighborhoodScore() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({
      neighborhoodId,
      factors,
    }: {
      neighborhoodId: number
      factors: { key: NeighborhoodScoreFactorKey; score: number; notes?: string }[]
    }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: NeighborhoodProfile }>(`/admin/neighborhoods/${neighborhoodId}/score`, { factors })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['neighborhoods'] })
      queryClient.invalidateQueries({ queryKey: ['neighborhoods', 'detail', variables.neighborhoodId] })
    },
  })
}

export function useAdminAddPoi() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({
      neighborhoodId,
      poi_type,
      name,
      lat,
      lng,
    }: {
      neighborhoodId: number
      poi_type: PoiType
      name: string
      lat?: number
      lng?: number
    }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: NeighborhoodPoi }>(`/admin/neighborhoods/${neighborhoodId}/pois`, { poi_type, name, lat, lng })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['neighborhoods', 'detail', variables.neighborhoodId] })
    },
  })
}

export function useAdminDeletePoi() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ poiId }: { poiId: number; neighborhoodId: number }) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/neighborhood-pois/${poiId}`)
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['neighborhoods', 'detail', variables.neighborhoodId] })
    },
  })
}

export function useAdminCommunityNotes(status: CommunityNote['status'] = 'pending') {
  return useQuery({
    queryKey: ['admin', 'community-notes', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<CommunityNote>>('/admin/community-notes', {
        params: { status },
      })
      return data
    },
  })
}

export function useApproveCommunityNote() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: CommunityNote }>(`/admin/community-notes/${id}/approve`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'community-notes'] }),
  })
}

export function useRejectCommunityNote() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, reason }: { id: number; reason: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: CommunityNote }>(`/admin/community-notes/${id}/reject`, { reason })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'community-notes'] }),
  })
}

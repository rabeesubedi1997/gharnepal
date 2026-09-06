import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export type YesNoUnknown = 'yes' | 'no' | 'in_process' | 'unknown'
export type RiskLevel = 'none' | 'low' | 'medium' | 'high' | 'unknown'

export interface LandProfile {
  kitta_number: string | null
  lalpurja_available: YesNoUnknown
  lalpurja_document_url: string | null
  road_access: boolean
  road_width_meters: number | null
  road_type: 'blacktop' | 'gravel' | 'dirt' | 'none'
  water_access: 'municipal' | 'well' | 'none' | 'unknown'
  electricity_access: boolean
  drainage_access: 'yes' | 'no' | 'unknown'
  land_classification: 'residential' | 'agricultural' | 'commercial' | 'guthi' | 'other'
  flood_risk: RiskLevel
  landslide_risk: RiskLevel
  nearby_development_notes: string | null
  document_verification_status: 'unverified' | 'partial' | 'verified'
  verified_at: string | null
  completeness_percent: number
}

export type LandProfileInput = Partial<Omit<LandProfile, 'lalpurja_document_url' | 'document_verification_status' | 'verified_at' | 'completeness_percent'>>

export function useLandProfile(propertyId: number | undefined) {
  return useQuery({
    queryKey: ['land-profile', propertyId],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: LandProfile }>(`/properties/${propertyId}/land-profile`)
      return data.data
    },
    enabled: !!propertyId,
  })
}

export function useSaveLandProfile() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ propertyId, input }: { propertyId: number; input: LandProfileInput }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: LandProfile }>(`/properties/${propertyId}/land-profile`, input)
      return data.data
    },
    onSuccess: (_data, variables) => {
      // The listing detail page embeds the land profile inside its own query
      // (['listings', 'detail', slug]) rather than reading useLandProfile, so
      // that cache needs invalidating too or the checklist/admin panel go stale.
      queryClient.invalidateQueries({ queryKey: ['land-profile', variables.propertyId] })
      queryClient.invalidateQueries({ queryKey: ['listings'] })
      queryClient.invalidateQueries({ queryKey: ['owner', 'properties'] })
    },
  })
}

export function useUploadLandDocument() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ propertyId, file }: { propertyId: number; file: File }) => {
      const form = new FormData()
      form.append('file', file)
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: LandProfile }>(`/properties/${propertyId}/land-profile/document`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: (_data, variables) => {
      // The listing detail page embeds the land profile inside its own query
      // (['listings', 'detail', slug]) rather than reading useLandProfile, so
      // that cache needs invalidating too or the checklist/admin panel go stale.
      queryClient.invalidateQueries({ queryKey: ['land-profile', variables.propertyId] })
      queryClient.invalidateQueries({ queryKey: ['listings'] })
      queryClient.invalidateQueries({ queryKey: ['owner', 'properties'] })
    },
  })
}

export function useVerifyLandProfile() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ propertyId, status }: { propertyId: number; status: 'unverified' | 'partial' | 'verified' }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: LandProfile }>(`/admin/properties/${propertyId}/land-profile/verify`, {
        document_verification_status: status,
      })
      return data.data
    },
    onSuccess: (_data, variables) => {
      // The listing detail page embeds the land profile inside its own query
      // (['listings', 'detail', slug]) rather than reading useLandProfile, so
      // that cache needs invalidating too or the checklist/admin panel go stale.
      queryClient.invalidateQueries({ queryKey: ['land-profile', variables.propertyId] })
      queryClient.invalidateQueries({ queryKey: ['listings'] })
      queryClient.invalidateQueries({ queryKey: ['owner', 'properties'] })
    },
  })
}

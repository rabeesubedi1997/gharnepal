import { useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { MediaItem } from './listings'
import type { LandProfile } from './landProfile'

export type PropertyType = 'room' | 'apartment' | 'house' | 'land' | 'commercial'
export type AreaUnit = 'sqft' | 'sqm' | 'aana' | 'ropani' | 'kattha' | 'dhur'
export type FurnishedStatus = 'unfurnished' | 'semi' | 'full'
export type ParkingType = 'car' | 'bike' | 'both'
export type FacingDirection = 'north' | 'south' | 'east' | 'west' | 'northeast' | 'northwest' | 'southeast' | 'southwest'

export interface FloorBreakdownInput {
  label: string
  area_sqft?: number
  description?: string
}

export interface FloorBreakdown {
  id: number
  label: string
  area_sqm: number | null
  display: { sqft: number } | null
  description: string | null
}

export interface AddressInput {
  province_id: number
  district_id: number
  municipality_id: number
  ward_id: number
  neighborhood_id?: number | null
  street_address?: string
  landmark?: string
  lat?: number
  lng?: number
}

export interface CreatePropertyInput {
  property_type: PropertyType
  area_value: number
  area_unit: AreaUnit
  bedrooms?: number
  bathrooms?: number
  floors?: number
  year_built?: number
  parking_spaces?: number
  parking_type?: ParkingType
  is_furnished?: FurnishedStatus
  facing_direction?: FacingDirection
  water_tank_capacity_liters?: number
  structural_notes?: string
  floor_breakdown?: FloorBreakdownInput[]
  address: AddressInput
}

export interface Property {
  id: number
  property_type: PropertyType
  area: {
    sqm: number | null
    entered_value: number | null
    entered_unit: AreaUnit | null
    display: Record<AreaUnit, number> | null
  }
  bedrooms: number | null
  bathrooms: number | null
  floors: number | null
  year_built: number | null
  parking_spaces: number | null
  parking_type: ParkingType | null
  is_furnished: FurnishedStatus | null
  facing_direction: FacingDirection | null
  water_tank_capacity_liters: number | null
  structural_notes: string | null
  floor_breakdown: FloorBreakdown[]
  address: {
    province?: { id: number; name: string }
    district?: { id: number; name: string }
    municipality?: { id: number; name: string }
    ward?: { id: number; ward_number: number }
    neighborhood?: { id: number; name: string } | null
    lat: number | null
    lng: number | null
  } | null
  media: MediaItem[]
  land_profile?: LandProfile | null
}

async function createProperty(input: CreatePropertyInput): Promise<Property> {
  await ensureCsrfCookie()
  const { data } = await apiClient.post<{ data: Property }>('/properties', input)
  return data.data
}

export function useCreateProperty() {
  return useMutation({ mutationFn: createProperty })
}

export function useDeletePropertyMedia() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ propertyId, mediaId }: { propertyId: number; mediaId: number }) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/properties/${propertyId}/media/${mediaId}`)
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['owner', 'properties'] })
      queryClient.invalidateQueries({ queryKey: ['property', variables.propertyId] })
    },
  })
}

export function useUploadPropertyMedia() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ propertyId, type, file }: { propertyId: number; type: 'image' | 'video' | 'floor_plan' | 'document'; file: File }) => {
      const form = new FormData()
      form.append('type', type)
      form.append('file', file)
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: MediaItem }>(`/properties/${propertyId}/media`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['owner', 'properties'] })
      queryClient.invalidateQueries({ queryKey: ['property', variables.propertyId] })
    },
  })
}

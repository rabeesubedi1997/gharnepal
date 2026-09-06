import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { PropertyType } from './properties'

export interface PropertyRequest {
  id: number
  purpose: 'sale' | 'rent'
  property_type: PropertyType | null
  budget_min: number | null
  budget_max: number | null
  bedrooms_min: number | null
  municipality: string | null
  notes: string | null
  status: 'open' | 'closed'
  posted_by: string | null
  is_mine: boolean
  created_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export interface PropertyRequestFilters {
  purpose?: 'sale' | 'rent'
  property_type?: PropertyType
  municipality_id?: number
}

export function usePropertyRequests(filters: PropertyRequestFilters = {}) {
  return useQuery({
    queryKey: ['property-requests', filters],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<PropertyRequest>>('/property-requests', { params: filters })
      return data
    },
  })
}

export function useMyPropertyRequests() {
  return useQuery({
    queryKey: ['property-requests', 'mine'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: PropertyRequest[] }>('/account/property-requests')
      return data.data
    },
  })
}

export interface CreatePropertyRequestInput {
  purpose: 'sale' | 'rent'
  property_type?: PropertyType
  budget_min?: number
  budget_max?: number
  bedrooms_min?: number
  municipality_id?: number
  notes?: string
}

export function useCreatePropertyRequest() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: CreatePropertyRequestInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: PropertyRequest }>('/property-requests', input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['property-requests'] })
    },
  })
}

export function useClosePropertyRequest() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: PropertyRequest }>(`/property-requests/${id}/close`)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['property-requests'] })
    },
  })
}

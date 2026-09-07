import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

export interface Province {
  id: number
  name: string
  name_ne: string | null
  code: string
}

export interface District {
  id: number
  province_id: number
  name: string
  name_ne: string | null
  code: string
}

export interface Municipality {
  id: number
  district_id: number
  name: string
  name_ne: string | null
  type: 'metropolitan' | 'sub_metropolitan' | 'municipality' | 'rural_municipality'
  code: string
  ward_count: number
  image_url: string | null
}

export interface Ward {
  id: number
  municipality_id: number
  ward_number: number
  name: string | null
}

export interface Neighborhood {
  id: number
  ward_id: number
  name: string
  name_ne: string | null
}

async function fetchList<T>(path: string, params?: Record<string, number>): Promise<T[]> {
  const { data } = await apiClient.get<{ data: T[] }>(path, { params })
  return data.data
}

export function useProvinces() {
  return useQuery({
    queryKey: ['locations', 'provinces'],
    queryFn: () => fetchList<Province>('/locations/provinces'),
    staleTime: 60 * 60 * 1000,
  })
}

export function useDistricts(provinceId?: number) {
  return useQuery({
    queryKey: ['locations', 'districts', provinceId],
    queryFn: () => fetchList<District>('/locations/districts', provinceId ? { province_id: provinceId } : undefined),
    staleTime: 60 * 60 * 1000,
    enabled: !!provinceId,
  })
}

export function useMunicipalities(districtId?: number) {
  return useQuery({
    queryKey: ['locations', 'municipalities', districtId],
    queryFn: () => fetchList<Municipality>('/locations/municipalities', districtId ? { district_id: districtId } : undefined),
    staleTime: 60 * 60 * 1000,
    enabled: districtId === undefined ? true : !!districtId,
  })
}

export function useWards(municipalityId?: number) {
  return useQuery({
    queryKey: ['locations', 'wards', municipalityId],
    queryFn: () => fetchList<Ward>('/locations/wards', municipalityId ? { municipality_id: municipalityId } : undefined),
    staleTime: 60 * 60 * 1000,
    enabled: !!municipalityId,
  })
}

export function useNeighborhoods(wardId?: number) {
  return useQuery({
    queryKey: ['locations', 'neighborhoods', wardId],
    queryFn: () => fetchList<Neighborhood>('/locations/neighborhoods', wardId ? { ward_id: wardId } : undefined),
    staleTime: 60 * 60 * 1000,
    enabled: !!wardId,
  })
}

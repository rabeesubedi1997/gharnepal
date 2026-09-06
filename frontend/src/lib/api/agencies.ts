import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'
import type { ListingSummary } from './listings'
import type { EffectiveSeo } from './seo'

export interface AgencySummary {
  id: number
  name: string
  slug: string
  logo_url: string | null
  description: string | null
  is_verified: boolean
  member_count: number
  active_listings_count: number
}

export interface AgencyProfile extends AgencySummary {
  seo: EffectiveSeo
  verified_at: string | null
  members: { name: string; role_in_agency: 'owner_admin' | 'agent' }[]
  active_listings: ListingSummary[]
}

export function useAgencies() {
  return useQuery({
    queryKey: ['agencies'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AgencySummary[] }>('/agencies')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

export function useAgency(slug: string | undefined) {
  return useQuery({
    queryKey: ['agencies', 'detail', slug],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AgencyProfile }>(`/agencies/${slug}`)
      return data.data
    },
    enabled: !!slug,
  })
}

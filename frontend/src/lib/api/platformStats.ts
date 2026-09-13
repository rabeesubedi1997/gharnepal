import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

export interface PlatformStats {
  published_listings: number
  verified_agencies: number
  phone_verified_owner_pct: number
  cities_covered: number
  active_alert_subscriptions: number
  land_price_per_aana_by_city: { municipality: string; median_price_per_aana: number; listing_count: number }[]
}

export function usePlatformStats() {
  return useQuery({
    queryKey: ['platformStats'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: PlatformStats }>('/platform-stats')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

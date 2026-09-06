import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

export interface ListingAnalytics {
  views_count: number
  favorites_count: number
  inquiries_count: number
  viewing_requests_count: number
}

export function useListingAnalytics(listingId: number | undefined, enabled: boolean) {
  return useQuery({
    queryKey: ['listing-analytics', listingId],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: ListingAnalytics }>(`/owner/listings/${listingId}/analytics`)
      return data.data
    },
    enabled: enabled && !!listingId,
  })
}

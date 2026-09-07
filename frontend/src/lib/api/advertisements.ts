import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

/** Keep in sync with `App\Domain\Marketing\AdvertisementPlacement` on the
 * backend — this is the picker shown in the admin Advertising page, and the
 * only slots any page actually queries for. */
export const PLACEMENTS = [
  { value: 'home_before_footer', label: 'Homepage — above the footer' },
  { value: 'search_sidebar', label: 'Search results — sidebar' },
  { value: 'listing_detail_sidebar', label: 'Listing detail — sidebar' },
] as const

export type AdPlacement = (typeof PLACEMENTS)[number]['value']

export interface Advertisement {
  id: number
  title: string | null
  subtitle: string | null
  image_url: string
  link_url: string | null
  cta_label: string | null
  placement: AdPlacement
  sort_order: number
  is_active: boolean
}

/** A slot renders nothing unless an active ad targets it — no placeholder ad space. */
export function useAdvertisements(placement: AdPlacement) {
  return useQuery({
    queryKey: ['advertisements', placement],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Advertisement[] }>('/advertisements', { params: { placement } })
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

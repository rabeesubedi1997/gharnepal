import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

export interface Banner {
  id: number
  title: string | null
  subtitle: string | null
  image_url: string
  link_url: string | null
  cta_label: string | null
  sort_order: number
  is_active: boolean
}

export function useBanners() {
  return useQuery({
    queryKey: ['banners'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Banner[] }>('/banners')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

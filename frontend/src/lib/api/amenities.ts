import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

export interface Amenity {
  id: number
  key: string
  name: string
  name_ne: string | null
  category: string | null
  icon: string | null
}

export function useAmenities() {
  return useQuery({
    queryKey: ['amenities'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Amenity[] }>('/amenities')
      return data.data
    },
    staleTime: 60 * 60 * 1000,
  })
}

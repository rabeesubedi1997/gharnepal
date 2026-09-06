import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface Rating {
  id: number
  score: number
  comment: string | null
  user: { name: string } | null
  created_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useListingRatings(listingId: number | undefined) {
  return useQuery({
    queryKey: ['ratings', listingId],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<Rating>>(`/listings/${listingId}/ratings`)
      return data
    },
    enabled: !!listingId,
  })
}

export function useSubmitRating() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, score, comment }: { listingId: number; score: number; comment?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: Rating }>(`/listings/${listingId}/ratings`, { score, comment })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['ratings', variables.listingId] })
      queryClient.invalidateQueries({ queryKey: ['listings'] })
    },
  })
}

export function useDeleteRating() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (listingId: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/listings/${listingId}/ratings`)
    },
    onSuccess: (_data, listingId) => {
      queryClient.invalidateQueries({ queryKey: ['ratings', listingId] })
      queryClient.invalidateQueries({ queryKey: ['listings'] })
    },
  })
}

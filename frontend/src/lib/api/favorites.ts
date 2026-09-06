import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { ListingSummary } from './listings'

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

/**
 * `enabled` defaults to true for callers that are already behind
 * <RequireAuth> (e.g. the Saved page). Public pages that render for guests
 * too (e.g. ListingDetail) must pass `!!user` so this never fires — and
 * fails — for an unauthenticated visitor.
 */
export function useFavorites(enabled = true) {
  return useQuery({
    queryKey: ['favorites'],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<ListingSummary>>('/account/favorites')
      return data
    },
    enabled,
  })
}

export function useAddFavorite() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (listingId: number) => {
      await ensureCsrfCookie()
      await apiClient.post('/account/favorites', { listing_id: listingId })
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['favorites'] }),
  })
}

export function useRemoveFavorite() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (listingId: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/account/favorites/${listingId}`)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['favorites'] }),
  })
}

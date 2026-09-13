import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { ListingSummary } from './listings'

export interface FavoriteCollection {
  id: number
  name: string
  share_token: string
  listings_count: number
  created_at: string
}

export function useFavoriteCollections() {
  return useQuery({
    queryKey: ['favoriteCollections'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: FavoriteCollection[] }>('/account/favorite-collections')
      return data.data
    },
  })
}

export function useCreateFavoriteCollection() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (name: string) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: FavoriteCollection }>('/account/favorite-collections', { name })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['favoriteCollections'] }),
  })
}

export function useRenameFavoriteCollection() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, name }: { id: number; name: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: FavoriteCollection }>(`/account/favorite-collections/${id}`, { name })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['favoriteCollections'] }),
  })
}

export function useDeleteFavoriteCollection() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/account/favorite-collections/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['favoriteCollections'] })
      queryClient.invalidateQueries({ queryKey: ['favorites'] })
    },
  })
}

/** null = "All saved" (everything); a number = only that collection's listings. */
export function useFavoritesByCollection(collectionId: number | null) {
  return useQuery({
    queryKey: ['favorites', { collectionId }],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: ListingSummary[] }>('/account/favorites', {
        params: collectionId != null ? { collection_id: collectionId } : undefined,
      })
      return data.data
    },
  })
}

export function useMoveFavoriteToCollection() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, collectionId }: { listingId: number; collectionId: number | null }) => {
      await ensureCsrfCookie()
      await apiClient.put(`/account/favorites/${listingId}`, { collection_id: collectionId })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['favorites'] })
      queryClient.invalidateQueries({ queryKey: ['favoriteCollections'] })
    },
  })
}

export interface SharedCollection {
  collection: { name: string; curated_by: string }
  data: ListingSummary[]
}

export function useSharedCollection(token: string | undefined) {
  return useQuery({
    queryKey: ['sharedCollection', token],
    queryFn: async () => {
      const { data } = await apiClient.get<SharedCollection>(`/collections/${token}`)
      return data
    },
    enabled: !!token,
    retry: false,
  })
}

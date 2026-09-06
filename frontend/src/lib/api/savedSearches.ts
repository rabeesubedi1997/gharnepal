import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { SearchFilters } from './listings'

export interface SavedSearch {
  id: number
  name: string
  filters: SearchFilters
  alert_frequency: 'instant' | 'daily' | 'weekly' | 'off'
  last_notified_at: string | null
  created_at: string
}

export function useSavedSearches() {
  return useQuery({
    queryKey: ['saved-searches'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: SavedSearch[] }>('/account/saved-searches')
      return data.data
    },
  })
}

export function useCreateSavedSearch() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { name: string; filters: SearchFilters }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: SavedSearch }>('/account/saved-searches', input)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['saved-searches'] }),
  })
}

export function useDeleteSavedSearch() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/account/saved-searches/${id}`)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['saved-searches'] }),
  })
}

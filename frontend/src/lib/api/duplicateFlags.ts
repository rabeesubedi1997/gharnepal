import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export type DuplicateFlagStatus = 'unreviewed' | 'confirmed' | 'dismissed'

export interface DuplicateListingFlag {
  id: number
  listing: { id: number; slug: string; title: string; price: number }
  duplicate_of: { id: number; slug: string; title: string; price: number }
  match_score: number
  match_reasons: string[]
  status: DuplicateFlagStatus
  created_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useDuplicateFlags(status: DuplicateFlagStatus = 'unreviewed') {
  return useQuery({
    queryKey: ['admin', 'duplicate-flags', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<DuplicateListingFlag>>('/admin/duplicate-flags', { params: { status } })
      return data
    },
  })
}

function useTransitionFlag(action: 'confirm' | 'dismiss') {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: DuplicateListingFlag }>(`/admin/duplicate-flags/${id}/${action}`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'duplicate-flags'] }),
  })
}

export const useConfirmDuplicateFlag = () => useTransitionFlag('confirm')
export const useDismissDuplicateFlag = () => useTransitionFlag('dismiss')

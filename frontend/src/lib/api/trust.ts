import { useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface TrustFactorBreakdown {
  key: string
  label: string
  description: string
  points_awarded: number
  max_points: number
  explanation: string
}

export interface TrustScore {
  score: number
  computed_score: number
  is_overridden: boolean
  computed_at: string
  breakdown: TrustFactorBreakdown[]
}

export function useSetTrustOverride() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, override_score, note }: { listingId: number; override_score: number; note: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: TrustScore }>(`/admin/listings/${listingId}/trust-override`, { override_score, note })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['listings'] }),
  })
}

export function useClearTrustOverride() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (listingId: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.delete<{ data: TrustScore }>(`/admin/listings/${listingId}/trust-override`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['listings'] }),
  })
}

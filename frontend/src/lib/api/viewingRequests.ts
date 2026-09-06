import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export type ViewingStatus = 'requested' | 'confirmed' | 'rescheduled' | 'completed' | 'cancelled' | 'no_show'

export interface VisitVerification {
  visited: boolean
  matched_listing: boolean | null
  price_accurate: boolean | null
  host_attended: boolean | null
  documents_shown: boolean | null
  overall_comment: string | null
}

export interface ViewingRequest {
  id: number
  listing: { id: number; slug: string; title: string }
  requester: { id: number; name: string } | null
  host: { id: number; name: string } | null
  proposed_datetime: string
  confirmed_datetime: string | null
  status: ViewingStatus
  notes: string | null
  visit_verification: VisitVerification | null
  created_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useViewingRequests(as: 'requester' | 'host') {
  return useQuery({
    queryKey: ['viewing-requests', as],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<ViewingRequest>>('/viewing-requests', { params: { as } })
      return data.data
    },
  })
}

export function useRequestViewing() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { listingId: number; proposedDatetime: string; notes?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: ViewingRequest }>('/viewing-requests', {
        listing_id: input.listingId,
        proposed_datetime: input.proposedDatetime,
        notes: input.notes,
      })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['viewing-requests'] }),
  })
}

export function useTransitionViewing() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, action, datetime }: { id: number; action: 'confirm' | 'reschedule' | 'cancel' | 'complete'; datetime?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: ViewingRequest }>(`/viewing-requests/${id}/transition`, { action, datetime })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['viewing-requests'] }),
  })
}

export function useSubmitVisitVerification() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...input }: { id: number } & Partial<VisitVerification>) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: ViewingRequest }>(`/viewing-requests/${id}/visit-verification`, input)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['viewing-requests'] }),
  })
}

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export type ReportReason = 'fraud' | 'duplicate' | 'sold_already' | 'misleading' | 'inappropriate' | 'other'
export type ReportStatus = 'open' | 'reviewed' | 'dismissed' | 'action_taken'

export interface ListingReport {
  id: number
  listing: { id: number; slug: string; title: string }
  reported_by: { id: number; name: string } | null
  reason: ReportReason
  details: string | null
  status: ReportStatus
  resolution_note: string | null
  created_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useSubmitReport() {
  return useMutation({
    mutationFn: async ({ listingId, reason, details }: { listingId: number; reason: ReportReason; details?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: ListingReport }>(`/listings/${listingId}/reports`, { reason, details })
      return data.data
    },
  })
}

export function useAdminReports(status: ReportStatus = 'open') {
  return useQuery({
    queryKey: ['admin', 'reports', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<ListingReport>>('/admin/reports', { params: { status } })
      return data
    },
  })
}

export function useResolveReport() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, status, resolution_note }: { id: number; status: 'reviewed' | 'dismissed' | 'action_taken'; resolution_note?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: ListingReport }>(`/admin/reports/${id}/resolve`, { status, resolution_note })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'reports'] }),
  })
}

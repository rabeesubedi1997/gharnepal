import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export type VerificationType = 'identity' | 'agent_license' | 'agency_document'
export type VerificationStatus = 'pending' | 'approved' | 'rejected'

export interface UserVerification {
  id: number
  user: { id: number; name: string; email: string } | null
  type: VerificationType
  status: VerificationStatus
  document_url: string | null
  document_mime_type: string | null
  rejection_reason: string | null
  reviewed_at: string | null
  created_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useMyVerifications() {
  return useQuery({
    queryKey: ['verifications', 'mine'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: UserVerification[] }>('/account/verifications')
      return data.data
    },
    // An admin approving/rejecting elsewhere doesn't invalidate this query (no
    // websockets) — poll so a pending status updates without a manual refresh,
    // matching notifications' cadence.
    refetchInterval: 20000,
  })
}

export function useSubmitVerification() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ type, document }: { type: VerificationType; document: File }) => {
      const form = new FormData()
      form.append('type', type)
      form.append('document', document)
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: UserVerification }>('/account/verifications', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['verifications', 'mine'] }),
  })
}

export function useAdminVerifications(status: VerificationStatus = 'pending') {
  return useQuery({
    queryKey: ['admin', 'verifications', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<UserVerification>>('/admin/verifications', { params: { status } })
      return data
    },
  })
}

export function useApproveVerification() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: UserVerification }>(`/admin/verifications/${id}/approve`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'verifications'] }),
  })
}

export function useRejectVerification() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, reason }: { id: number; reason: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: UserVerification }>(`/admin/verifications/${id}/reject`, { reason })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'verifications'] }),
  })
}

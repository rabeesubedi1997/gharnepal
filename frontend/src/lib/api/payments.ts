import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface FeaturedPlan {
  key: string
  days: number
  price: number
  label: string
}

export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'refunded'

export interface PaymentTransaction {
  id: number
  plan_key: string
  plan_days: number
  amount: number
  currency: string
  gateway: string
  gateway_reference: string
  status: PaymentStatus
  completed_at: string | null
  created_at: string
  listing: { id: number; slug: string; title: string; featured_until: string | null } | null
  user?: { id: number; name: string } | null
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useFeaturedPlans() {
  return useQuery({
    queryKey: ['featured-plans'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: FeaturedPlan[] }>('/featured-plans')
      return data.data
    },
    staleTime: 60 * 60 * 1000,
  })
}

export function usePurchaseFeature() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, planKey }: { listingId: number; planKey: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: PaymentTransaction }>(`/listings/${listingId}/feature`, { plan_key: planKey })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['account', 'payments'] }),
  })
}

export function useConfirmPayment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ transactionId, outcome }: { transactionId: number; outcome: 'success' | 'failure' }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: PaymentTransaction }>(`/account/payments/${transactionId}/confirm`, { outcome })
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['account', 'payments'] })
      queryClient.invalidateQueries({ queryKey: ['owner', 'properties'] })
      queryClient.invalidateQueries({ queryKey: ['listings'] })
    },
  })
}

export function useOwnerPayments() {
  return useQuery({
    queryKey: ['account', 'payments'],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<PaymentTransaction>>('/account/payments')
      return data
    },
  })
}

export function useAdminPayments(status?: PaymentStatus) {
  return useQuery({
    queryKey: ['admin', 'payments', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<PaymentTransaction>>('/admin/payments', {
        params: status ? { status } : undefined,
      })
      return data
    },
  })
}

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

export interface PaymentGatewayOption {
  id: number
  provider: string
  label: string
  is_sandbox: boolean
}

/** What a gateway hands back right after purchase — how to actually get the buyer paying. */
export interface CheckoutInstruction {
  mode: 'inline' | 'redirect' | 'form_post'
  redirect_url: string | null
  form_fields: Record<string, string>
  instructions: string | null
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

/** Every gateway a buyer can actually pay with right now — public, no auth needed to see the list. */
export function usePaymentGatewayOptions() {
  return useQuery({
    queryKey: ['payment-gateways'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: PaymentGatewayOption[] }>('/payment-gateways')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

export function usePurchaseFeature() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, planKey, gatewayConfigId }: { listingId: number; planKey: string; gatewayConfigId: number }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: PaymentTransaction; checkout: CheckoutInstruction }>(
        `/listings/${listingId}/feature`,
        { plan_key: planKey, gateway_config_id: gatewayConfigId },
      )
      return data
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

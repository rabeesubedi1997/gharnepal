import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface GatewayCredentialField {
  key: string
  label: string
  type: 'text' | 'password'
  required: boolean
}

export interface GatewayCatalogEntry {
  provider: string
  label: string
  fields: GatewayCredentialField[]
}

export interface GatewayCredentialValue {
  value: string | null
  configured: boolean
}

export interface AdminPaymentGateway {
  id: number
  provider: string
  label: string
  is_enabled: boolean
  is_sandbox: boolean
  sort_order: number
  instructions: string | null
  credentials: Record<string, GatewayCredentialValue>
  created_at: string
  updated_at: string
}

export function useGatewayCatalog() {
  return useQuery({
    queryKey: ['admin', 'payment-gateways', 'catalog'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: GatewayCatalogEntry[] }>('/admin/payment-gateways/catalog')
      return data.data
    },
    staleTime: Infinity, // static — the supported provider list only changes with a deploy
  })
}

export function useAdminPaymentGateways() {
  return useQuery({
    queryKey: ['admin', 'payment-gateways'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminPaymentGateway[] }>('/admin/payment-gateways')
      return data.data
    },
  })
}

export interface GatewayInput {
  provider?: string
  label?: string
  is_enabled?: boolean
  is_sandbox?: boolean
  sort_order?: number
  instructions?: string | null
  credentials?: Record<string, string>
}

export function useCreateGateway() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: GatewayInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AdminPaymentGateway }>('/admin/payment-gateways', input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'payment-gateways'] })
      queryClient.invalidateQueries({ queryKey: ['payment-gateways'] })
    },
  })
}

export function useUpdateGateway() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...input }: GatewayInput & { id: number }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: AdminPaymentGateway }>(`/admin/payment-gateways/${id}`, input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'payment-gateways'] })
      queryClient.invalidateQueries({ queryKey: ['payment-gateways'] })
    },
  })
}

export function useDeleteGateway() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/payment-gateways/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'payment-gateways'] })
      queryClient.invalidateQueries({ queryKey: ['payment-gateways'] })
    },
  })
}

export function useMarkPaymentPaid() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (transactionId: number) => {
      await ensureCsrfCookie()
      await apiClient.patch(`/admin/payments/${transactionId}/mark-paid`)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'payments'] }),
  })
}

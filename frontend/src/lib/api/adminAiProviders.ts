import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface AiProviderCredentialField {
  key: string
  label: string
  type: 'text' | 'password'
  required: boolean
}

export interface AiProviderCatalogEntry {
  provider: string
  label: string
  fields: AiProviderCredentialField[]
}

export interface AiProviderCredentialValue {
  value: string | null
  configured: boolean
}

export interface AdminAiProviderConfig {
  id: number
  provider: string
  label: string
  is_enabled: boolean
  credentials: Record<string, AiProviderCredentialValue>
  created_at: string
  updated_at: string
}

export function useAiProviderCatalog() {
  return useQuery({
    queryKey: ['admin', 'ai-providers', 'catalog'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AiProviderCatalogEntry[] }>('/admin/ai-providers/catalog')
      return data.data
    },
    staleTime: Infinity, // static — the supported provider list only changes with a deploy
  })
}

export function useAdminAiProviders() {
  return useQuery({
    queryKey: ['admin', 'ai-providers'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminAiProviderConfig[] }>('/admin/ai-providers')
      return data.data
    },
  })
}

export interface AiProviderInput {
  provider?: string
  label?: string
  is_enabled?: boolean
  credentials?: Record<string, string>
}

export function useCreateAiProvider() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: AiProviderInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AdminAiProviderConfig }>('/admin/ai-providers', input)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'ai-providers'] }),
  })
}

export function useUpdateAiProvider() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...input }: AiProviderInput & { id: number }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: AdminAiProviderConfig }>(`/admin/ai-providers/${id}`, input)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'ai-providers'] }),
  })
}

export function useDeleteAiProvider() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/ai-providers/${id}`)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'ai-providers'] }),
  })
}

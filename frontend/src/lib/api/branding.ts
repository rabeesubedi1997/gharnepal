import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface Branding {
  site_name: string
  favicon_url: string | null
  app_icon_url: string | null
  updated_at: string | null
}

/** Public, unauthenticated — safe to fetch on every page load. */
export function useBranding() {
  return useQuery({
    queryKey: ['branding'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Branding }>('/branding')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

export function useAdminBranding() {
  return useQuery({
    queryKey: ['admin', 'branding'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Branding }>('/admin/branding')
      return data.data
    },
  })
}

export function useUpdateBranding() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { site_name?: string; favicon?: File; app_icon?: File }) => {
      await ensureCsrfCookie()
      const form = new FormData()
      if (input.site_name !== undefined) form.append('site_name', input.site_name)
      if (input.favicon) form.append('favicon', input.favicon)
      if (input.app_icon) form.append('app_icon', input.app_icon)
      const { data } = await apiClient.post<{ data: Branding }>('/admin/branding', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'branding'] })
      queryClient.invalidateQueries({ queryKey: ['branding'] })
    },
  })
}

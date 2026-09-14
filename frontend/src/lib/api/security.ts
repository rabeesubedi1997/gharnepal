import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface CaptchaConfig {
  enabled: boolean
  site_key: string | null
}

/** Public, unauthenticated — the registration form asks this whether to render the widget at all. */
export function useCaptchaConfig() {
  return useQuery({
    queryKey: ['security', 'captcha'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: CaptchaConfig }>('/security/captcha')
      return data.data
    },
    staleTime: 5 * 60 * 1000,
  })
}

export interface AdminSecuritySettings {
  recaptcha_enabled: boolean
  recaptcha_site_key: string | null
  recaptcha_secret_configured: boolean
  is_active: boolean
}

export function useAdminSecurity() {
  return useQuery({
    queryKey: ['admin', 'security'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminSecuritySettings }>('/admin/security')
      return data.data
    },
  })
}

export function useUpdateSecurity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { recaptcha_enabled?: boolean; recaptcha_site_key?: string; recaptcha_secret_key?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AdminSecuritySettings }>('/admin/security', input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'security'] })
      queryClient.invalidateQueries({ queryKey: ['security', 'captcha'] })
    },
  })
}

export interface MailTestResult {
  sent: boolean
  to: string
  mailer: string
  error: string | null
}

export function useSendTestEmail() {
  return useMutation({
    mutationFn: async () => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: MailTestResult }>('/admin/mail-test')
      return data.data
    },
  })
}

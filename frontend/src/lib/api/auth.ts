import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface AuthUser {
  id: number
  name: string
  email: string
  phone: string | null
  locale: string
  email_verified: boolean
  phone_verified: boolean
  roles: string[]
}

async function fetchMe(): Promise<AuthUser | null> {
  try {
    const { data } = await apiClient.get<{ data: AuthUser }>('/auth/me')
    return data.data
  } catch (error: any) {
    if (error?.response?.status === 401) return null
    throw error
  }
}

export function useCurrentUser() {
  return useQuery({
    queryKey: ['auth', 'me'],
    queryFn: fetchMe,
    staleTime: 5 * 60 * 1000,
    retry: false,
  })
}

export function useHasRole(role: string): boolean {
  const { data } = useCurrentUser()
  return data?.roles.includes(role) ?? false
}

interface RegisterInput {
  name: string
  email: string
  password: string
  password_confirmation: string
}

interface LoginInput {
  email: string
  password: string
}

export function useRegister() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: RegisterInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AuthUser }>('/auth/register', input)
      return data.data
    },
    onSuccess: (user) => queryClient.setQueryData(['auth', 'me'], user),
  })
}

export function useLogin() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: LoginInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AuthUser }>('/auth/login', input)
      return data.data
    },
    onSuccess: (user) => queryClient.setQueryData(['auth', 'me'], user),
  })
}

export function useLogout() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await apiClient.post('/auth/logout')
    },
    onSuccess: () => queryClient.setQueryData(['auth', 'me'], null),
  })
}

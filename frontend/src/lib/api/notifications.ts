import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import { useCurrentUser } from './auth'

export interface AppNotification {
  id: string
  type: string | null
  data: Record<string, unknown>
  read_at: string | null
  created_at: string
}

interface NotificationsResponse {
  data: AppNotification[]
  meta: { current_page: number; last_page: number; unread_count: number }
}

export function useNotifications() {
  const { data: user } = useCurrentUser()
  return useQuery({
    queryKey: ['notifications'],
    queryFn: async () => {
      const { data } = await apiClient.get<NotificationsResponse>('/notifications')
      return data
    },
    enabled: !!user,
    refetchInterval: 20000,
  })
}

export function useMarkNotificationRead() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      await ensureCsrfCookie()
      await apiClient.patch(`/notifications/${id}/read`)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  })
}

export function useMarkAllNotificationsRead() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await ensureCsrfCookie()
      await apiClient.patch('/notifications/read-all')
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  })
}

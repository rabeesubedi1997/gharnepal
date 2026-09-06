import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface Message {
  id: number
  conversation_id: number
  body: string
  sender_id: number
  is_mine: boolean
  read_at: string | null
  created_at: string
}

export interface Conversation {
  id: number
  listing: { id: number; slug: string; title: string; cover_image_url: string | null } | null
  property_request: { id: number; purpose: 'sale' | 'rent'; property_type: string | null } | null
  other_participant: { id: number; name: string } | null
  status: 'open' | 'archived'
  last_message_at: string | null
  unread_count: number
  messages: Message[]
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useConversations() {
  return useQuery({
    queryKey: ['conversations'],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<Conversation>>('/conversations')
      return data.data
    },
    // Polling keeps the inbox's unread counts fresh without websockets (see plan: Phase 3 note).
    refetchInterval: 15000,
  })
}

export function useConversation(id: number | undefined) {
  return useQuery({
    queryKey: ['conversations', id],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Conversation }>(`/conversations/${id}`)
      return data.data
    },
    enabled: !!id,
    refetchInterval: 4000,
  })
}

export function useStartConversation() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { listingId?: number; propertyRequestId?: number; message: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: Conversation }>('/conversations', {
        listing_id: input.listingId,
        property_request_id: input.propertyRequestId,
        message: input.message,
      })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['conversations'] }),
  })
}

export function useSendMessage() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ conversationId, body }: { conversationId: number; body: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: Message }>(`/conversations/${conversationId}/messages`, { body })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['conversations', variables.conversationId] })
      queryClient.invalidateQueries({ queryKey: ['conversations'] })
    },
  })
}

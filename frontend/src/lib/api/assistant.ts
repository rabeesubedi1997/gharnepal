import { useMutation } from '@tanstack/react-query'
import { apiClient } from './client'
import type { ListingSummary } from './listings'

export interface AssistantFiltersApplied {
  purpose: 'rent' | 'sale' | null
  property_type: string | null
  location: string | null
  price_label: string | null
  bedrooms_min: number | null
  amenities: string[]
}

export interface AssistantChatResponse {
  conversation_id: number
  guest_token: string
  reply: string
  listings: ListingSummary[]
  filters_applied: AssistantFiltersApplied
}

export interface AssistantChatInput {
  message: string
  conversation_id?: number
  guest_token?: string
}

async function sendAssistantMessage(input: AssistantChatInput): Promise<AssistantChatResponse> {
  const { data } = await apiClient.post<AssistantChatResponse>('/assistant/chat', input)
  return data
}

/** No CSRF cookie needed here — unlike the mutations in listings.ts, this
 * endpoint is guest-friendly and doesn't touch session-authenticated state. */
export function useSendAssistantMessage() {
  return useMutation({ mutationFn: sendAssistantMessage })
}

import { useCallback, useEffect, useState } from 'react'
import { useSendAssistantMessage } from './api/assistant'
import type { AssistantFiltersApplied } from './api/assistant'
import type { ListingSummary } from './api/listings'

const CONVERSATION_KEY = 'gharnepal:assistant:conversation-id'
const GUEST_TOKEN_KEY = 'gharnepal:assistant:guest-token'
const MESSAGES_KEY = 'gharnepal:assistant:messages'

export interface AssistantChatMessage {
  id: string
  role: 'user' | 'assistant'
  text: string
  listings?: ListingSummary[]
  filtersApplied?: AssistantFiltersApplied
}

function randomToken(): string {
  try {
    return crypto.randomUUID()
  } catch {
    return Math.random().toString(36).slice(2) + Date.now().toString(36)
  }
}

/** Guest identity + conversation continuity persisted client-side — the
 * backend's AiConversation only knows a guest by this token (see
 * PropertySearchParser / AssistantService), there's no session of its own. */
export function useAssistantChat() {
  const [conversationId, setConversationId] = useState<number | null>(() => {
    try {
      const stored = localStorage.getItem(CONVERSATION_KEY)
      return stored ? Number(stored) : null
    } catch {
      return null
    }
  })

  const [guestToken] = useState<string>(() => {
    try {
      const existing = localStorage.getItem(GUEST_TOKEN_KEY)
      if (existing) return existing
      const created = randomToken()
      localStorage.setItem(GUEST_TOKEN_KEY, created)
      return created
    } catch {
      return randomToken()
    }
  })

  const [messages, setMessages] = useState<AssistantChatMessage[]>(() => {
    try {
      const stored = localStorage.getItem(MESSAGES_KEY)
      return stored ? (JSON.parse(stored) as AssistantChatMessage[]) : []
    } catch {
      return []
    }
  })

  useEffect(() => {
    try {
      localStorage.setItem(MESSAGES_KEY, JSON.stringify(messages))
    } catch {
      // best-effort only — worst case history doesn't survive a reload
    }
  }, [messages])

  useEffect(() => {
    try {
      if (conversationId != null) localStorage.setItem(CONVERSATION_KEY, String(conversationId))
    } catch {
      // best-effort only
    }
  }, [conversationId])

  const mutation = useSendAssistantMessage()

  const sendMessage = useCallback(
    (text: string) => {
      const trimmed = text.trim()
      if (!trimmed) return

      setMessages((prev) => [...prev, { id: randomToken(), role: 'user', text: trimmed }])

      mutation.mutate(
        { message: trimmed, conversation_id: conversationId ?? undefined, guest_token: guestToken },
        {
          onSuccess: (data) => {
            setConversationId(data.conversation_id)
            setMessages((prev) => [
              ...prev,
              { id: randomToken(), role: 'assistant', text: data.reply, listings: data.listings, filtersApplied: data.filters_applied },
            ])
          },
          onError: () => {
            setMessages((prev) => [
              ...prev,
              { id: randomToken(), role: 'assistant', text: "Sorry, something went wrong on our end — please try again." },
            ])
          },
        },
      )
    },
    [conversationId, guestToken, mutation],
  )

  const clearConversation = useCallback(() => {
    setConversationId(null)
    setMessages([])
    try {
      localStorage.removeItem(CONVERSATION_KEY)
      localStorage.removeItem(MESSAGES_KEY)
    } catch {
      // best-effort only
    }
  }, [])

  return { messages, sendMessage, clearConversation, isSending: mutation.isPending }
}

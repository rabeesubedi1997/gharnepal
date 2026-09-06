import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { MessageCircle, Send } from 'lucide-react'
import { useConversation, useConversations, useSendMessage, type Conversation } from '../../lib/api/messaging'
import { useCurrentUser } from '../../lib/api/auth'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'
import { clsx } from 'clsx'

/** A conversation is always about exactly one of a listing or a property request. */
function conversationSubtitle(c: Conversation): string {
  if (c.listing) return c.listing.title
  if (c.property_request) return `${c.property_request.purpose === 'rent' ? 'Rental' : 'Purchase'} request`
  return ''
}

export function Messages() {
  const { id } = useParams<{ id: string }>()
  const conversationId = id ? Number(id) : undefined
  const navigate = useNavigate()

  const { data: conversations, isPending, isError, refetch } = useConversations()

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-[320px_1fr]" style={{ minHeight: '70vh' }}>
      <Card className="flex flex-col overflow-hidden p-0">
        <div className="border-b border-stone-200 p-4">
          <h1 className="font-display text-lg font-semibold text-ink-900">Messages</h1>
        </div>
        <div className="flex-1 overflow-y-auto">
          {isPending && (
            <div className="flex flex-col gap-3 p-4">
              <Skeleton className="h-14 w-full" />
              <Skeleton className="h-14 w-full" />
            </div>
          )}
          {isError && (
            <div className="p-4">
              <ErrorState onRetry={refetch} />
            </div>
          )}
          {!isPending && !isError && conversations?.length === 0 && (
            <div className="p-4">
              <EmptyState
                icon={<MessageCircle className="h-8 w-8" aria-hidden="true" />}
                title="No messages yet"
                description="Conversations with owners and agents will show up here."
              />
            </div>
          )}
          {conversations?.map((c) => (
            <button
              key={c.id}
              onClick={() => navigate(`/messages/${c.id}`)}
              className={clsx(
                'flex w-full items-center gap-3 border-b border-stone-100 p-3 text-left hover:bg-stone-100',
                conversationId === c.id && 'bg-trust-100',
              )}
            >
              {c.listing?.cover_image_url ? (
                <img src={c.listing.cover_image_url} alt="" className="h-12 w-12 shrink-0 rounded-lg object-cover" />
              ) : (
                <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-stone-100 text-ink-700/40">
                  <MessageCircle className="h-5 w-5" />
                </div>
              )}
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-ink-900">{c.other_participant?.name ?? 'User'}</p>
                <p className="truncate text-xs text-ink-700/60">{conversationSubtitle(c)}</p>
              </div>
              {c.unread_count > 0 && (
                <span className="flex h-5 min-w-5 shrink-0 items-center justify-center rounded-full bg-accent-600 px-1 text-xs font-medium text-white">
                  {c.unread_count}
                </span>
              )}
            </button>
          ))}
        </div>
      </Card>

      <Card className="flex flex-col overflow-hidden p-0">
        {conversationId ? (
          <Thread conversationId={conversationId} />
        ) : (
          <div className="flex flex-1 items-center justify-center p-8">
            <p className="text-sm text-ink-700/60">Select a conversation to view messages.</p>
          </div>
        )}
      </Card>
    </div>
  )
}

function Thread({ conversationId }: { conversationId: number }) {
  const { data: conversation, isPending } = useConversation(conversationId)
  const { data: user } = useCurrentUser()
  const sendMessage = useSendMessage()
  const [body, setBody] = useState('')

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault()
    if (!body.trim()) return
    sendMessage.mutate(
      { conversationId, body: body.trim() },
      { onSuccess: () => setBody('') },
    )
  }

  if (isPending || !conversation) {
    return (
      <div className="flex flex-col gap-3 p-4">
        <Skeleton className="h-10 w-2/3" />
        <Skeleton className="h-10 w-1/2 self-end" />
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col">
      <div className="border-b border-stone-200 p-4">
        <p className="font-medium text-ink-900">{conversation.other_participant?.name}</p>
        <p className="text-xs text-ink-700/60">{conversationSubtitle(conversation)}</p>
      </div>
      <div className="flex-1 space-y-3 overflow-y-auto p-4">
        {conversation.messages.map((m) => (
          <div key={m.id} className={clsx('flex', m.is_mine ? 'justify-end' : 'justify-start')}>
            <div
              className={clsx(
                'max-w-[75%] rounded-lg px-3 py-2 text-sm',
                m.is_mine ? 'bg-trust-700 text-white' : 'bg-stone-100 text-ink-900',
              )}
            >
              {m.body}
              <p className={clsx('mt-1 text-[10px]', m.is_mine ? 'text-trust-100' : 'text-ink-700/50')}>
                {new Date(m.created_at).toLocaleString(undefined, { hour: '2-digit', minute: '2-digit', month: 'short', day: 'numeric' })}
              </p>
            </div>
          </div>
        ))}
        {user && conversation.messages.length === 0 && (
          <p className="text-center text-sm text-ink-700/60">Say hello to get the conversation started.</p>
        )}
      </div>
      <form onSubmit={handleSend} className="flex gap-2 border-t border-stone-200 p-3">
        <input
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Type a message…"
          className="h-10 flex-1 rounded-lg border border-stone-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
        <Button type="submit" size="md" isLoading={sendMessage.isPending} disabled={!body.trim()}>
          <Send className="h-4 w-4" />
        </Button>
      </form>
    </div>
  )
}

import { useState } from 'react'
import { Link } from 'react-router-dom'
import { MessageSquareText, ShieldAlert } from 'lucide-react'
import { useAdminConversation, useAdminConversations, type AdminConversation } from '../../lib/api/admin'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Input, Select } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

function threadSubject(c: AdminConversation): string {
  if (c.listing) return c.listing.title
  if (c.property_request) return `Request: ${c.property_request.property_type} for ${c.property_request.purpose}`
  return 'Direct message'
}

export function Messages() {
  const [status, setStatus] = useState<'open' | 'closed' | ''>('')
  const [q, setQ] = useState('')
  const [openId, setOpenId] = useState<number | null>(null)
  const { data, isPending, isError, refetch } = useAdminConversations({ status: status || undefined, q: q || undefined })

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={MessageSquareText}
        tone="warning"
        title="Messages"
        description="Read-only view of buyer/owner conversations — use it to investigate a reported thread. Admins never post into a conversation."
        action={
          <>
            <Input
              placeholder="Search by name or email"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              className="w-56"
            />
            <Select value={status} onChange={(e) => setStatus(e.target.value as 'open' | 'closed' | '')} className="w-32">
              <option value="">All</option>
              <option value="open">Open</option>
              <option value="closed">Closed</option>
            </Select>
          </>
        }
      />

      {isPending && (
        <div className="flex flex-col gap-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-20 w-full" />
          ))}
        </div>
      )}
      {isError && <ErrorState onRetry={refetch} />}
      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState
          icon={<ShieldAlert className="h-10 w-10" aria-hidden="true" />}
          title="No conversations found"
          description="Buyer and owner conversations will show up here as they happen."
        />
      )}

      <div className="flex flex-col gap-2">
        {data?.data.map((c) => (
          <Card
            key={c.id}
            role="button"
            tabIndex={0}
            onClick={() => setOpenId(c.id)}
            onKeyDown={(e) => e.key === 'Enter' && setOpenId(c.id)}
            className="flex cursor-pointer flex-col gap-2 p-4 transition-shadow hover:shadow-md sm:flex-row sm:items-center sm:justify-between"
          >
            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-sm font-medium text-ink-900">{threadSubject(c)}</span>
                <Badge tone={c.status === 'open' ? 'success' : 'neutral'}>{c.status}</Badge>
              </div>
              <p className="mt-0.5 text-xs text-ink-700/70">
                {c.buyer?.name ?? 'Unknown'} ({c.buyer?.email ?? '—'}) &harr; {c.owner?.name ?? 'Unknown'} ({c.owner?.email ?? '—'})
              </p>
              {c.last_message_preview && (
                <p className="mt-1 line-clamp-1 text-sm text-ink-700/80">{c.last_message_preview}</p>
              )}
            </div>
            <div className="shrink-0 text-right text-xs text-ink-700/60">
              <p>{c.messages_count ?? 0} messages</p>
              {c.last_message_at && <p>{new Date(c.last_message_at).toLocaleString()}</p>}
            </div>
          </Card>
        ))}
      </div>

      <ConversationDetailModal conversationId={openId} onClose={() => setOpenId(null)} />
    </div>
  )
}

function ConversationDetailModal({ conversationId, onClose }: { conversationId: number | null; onClose: () => void }) {
  const { data: conversation, isPending } = useAdminConversation(conversationId)

  return (
    <Modal open={conversationId != null} onClose={onClose} title={conversation ? threadSubject(conversation) : 'Conversation'}>
      {isPending && (
        <div className="flex flex-col gap-2">
          <Skeleton className="h-12 w-full" />
          <Skeleton className="h-12 w-3/4" />
          <Skeleton className="h-12 w-full" />
        </div>
      )}

      {conversation && (
        <div className="flex flex-col gap-4">
          {conversation.listing && (
            <Link to={`/listings/${conversation.listing.slug}`} className="text-sm font-medium text-link-600 hover:text-link-700">
              View listing: {conversation.listing.title}
            </Link>
          )}
          <div className="flex flex-col gap-2">
            {conversation.messages?.map((m) => (
              <div key={m.id} className="rounded-lg border border-stone-200 bg-stone-100/50 p-3">
                <p className="text-xs font-semibold text-ink-900">{m.sender?.name ?? 'Unknown sender'}</p>
                <p className="mt-1 whitespace-pre-wrap text-sm text-ink-700/90">{m.body}</p>
                <p className="mt-1 text-[11px] text-ink-700/50">{new Date(m.created_at).toLocaleString()}</p>
              </div>
            ))}
            {conversation.messages?.length === 0 && (
              <p className="text-sm text-ink-700/60">No messages yet.</p>
            )}
          </div>
        </div>
      )}
    </Modal>
  )
}

import { useEffect, useRef, useState } from 'react'
import { Mic, RotateCcw, Send, Sparkles, Volume2, VolumeX, X } from 'lucide-react'
import { clsx } from 'clsx'
import { Card } from '../ui/Card'
import { Button } from '../ui/Button'
import { PropertyCard } from '../property/PropertyCard'
import { useAssistantChat } from '../../lib/useAssistantChat'
import { useSpeechRecognition } from '../../lib/useSpeechRecognition'
import { useSpeechSynthesis } from '../../lib/useSpeechSynthesis'

const FILTER_CHIP_LABELS: Record<string, (value: unknown) => string> = {
  purpose: (v) => (v === 'rent' ? 'For rent' : 'For sale'),
  property_type: (v) => String(v).charAt(0).toUpperCase() + String(v).slice(1),
  location: (v) => String(v),
  price_label: (v) => String(v),
  bedrooms_min: (v) => `${v}+ bedrooms`,
}

/** A floating "Ask AI" chat widget for the rule-based property-search
 * assistant (see backend AssistantService/PropertySearchParser — no paid
 * LLM API involved). Mounted once in AppLayout, next to InstallAppPrompt. */
export function AssistantWidget() {
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState('')
  const { messages, sendMessage, clearConversation, isSending } = useAssistantChat()
  const scrollRef = useRef<HTMLDivElement>(null)
  const lastSpokenIdRef = useRef<string | null>(null)

  const speech = useSpeechSynthesis()
  const recognition = useSpeechRecognition((transcript) => {
    // Voice is meant to go straight to an answer, not just fill the box —
    // send immediately rather than making the user tap Send again.
    sendMessage(transcript)
  })

  useEffect(() => {
    if (open) scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages, open, isSending])

  useEffect(() => {
    const last = messages[messages.length - 1]
    if (last && last.role === 'assistant' && last.id !== lastSpokenIdRef.current) {
      lastSpokenIdRef.current = last.id
      speech.speak(last.text)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [messages])

  const submit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!draft.trim() || isSending) return
    sendMessage(draft)
    setDraft('')
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="Ask AI about properties"
        className="fixed bottom-20 right-4 z-40 flex items-center gap-2 rounded-full bg-trust-700 px-4 py-3 text-white shadow-lg transition-transform hover:scale-105 hover:bg-trust-600 print:hidden"
      >
        <Sparkles className="h-5 w-5" aria-hidden="true" />
        <span className="text-sm font-semibold">Ask AI</span>
      </button>
    )
  }

  return (
    <Card className="fixed bottom-4 right-4 z-50 flex h-[min(32rem,calc(100vh-2rem))] w-[calc(100vw-2rem)] max-w-sm flex-col overflow-hidden shadow-xl print:hidden">
      <div className="flex items-center justify-between gap-2 border-b border-stone-200 bg-trust-700 px-4 py-3 text-white">
        <div className="flex items-center gap-2">
          <Sparkles className="h-4 w-4" aria-hidden="true" />
          <p className="text-sm font-semibold">Ghar Nepal Assistant</p>
        </div>
        <div className="flex items-center gap-1">
          {speech.isSupported && (
            <button
              type="button"
              onClick={() => speech.setEnabled(!speech.enabled)}
              aria-label={speech.enabled ? 'Turn off spoken replies' : 'Turn on spoken replies'}
              aria-pressed={speech.enabled}
              className="rounded-md p-1.5 hover:bg-white/10"
            >
              {speech.enabled ? <Volume2 className="h-4 w-4" /> : <VolumeX className="h-4 w-4" />}
            </button>
          )}
          <button
            type="button"
            onClick={clearConversation}
            aria-label="Start a new conversation"
            className="rounded-md p-1.5 hover:bg-white/10"
          >
            <RotateCcw className="h-4 w-4" />
          </button>
          <button type="button" onClick={() => setOpen(false)} aria-label="Close" className="rounded-md p-1.5 hover:bg-white/10">
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>

      <div ref={scrollRef} className="flex-1 space-y-3 overflow-y-auto p-3">
        {messages.length === 0 && (
          <div className="rounded-lg bg-stone-100 p-3 text-sm text-ink-700">
            <p className="mb-1 font-medium text-ink-900">Tell me what you're looking for.</p>
            <p className="text-xs text-ink-700/70">e.g. "a room in Kathmandu under NPR 20,000" or "3 bhk house for sale in Lalitpur"</p>
          </div>
        )}
        {messages.map((m) => (
          <div key={m.id} className={clsx('flex', m.role === 'user' ? 'justify-end' : 'justify-start')}>
            <div
              className={clsx(
                'max-w-[85%] rounded-lg px-3 py-2 text-sm',
                m.role === 'user' ? 'bg-trust-700 text-white' : 'bg-stone-100 text-ink-900',
              )}
            >
              <p>{m.text}</p>
              {m.filtersApplied && (
                <div className="mt-1.5 flex flex-wrap gap-1">
                  {Object.entries(m.filtersApplied)
                    .filter(([key, value]) => key !== 'amenities' && value != null && FILTER_CHIP_LABELS[key])
                    .map(([key, value]) => (
                      <span key={key} className="rounded-full bg-white/70 px-2 py-0.5 text-[11px] font-medium text-ink-700">
                        {FILTER_CHIP_LABELS[key](value)}
                      </span>
                    ))}
                </div>
              )}
              {m.listings && m.listings.length > 0 && (
                <div className="mt-2 grid grid-cols-1 gap-2">
                  {m.listings.map((listing) => (
                    <div key={listing.id} className="w-full max-w-[16rem]">
                      <PropertyCard listing={listing} />
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        ))}
        {isSending && (
          <div className="flex justify-start">
            <div className="rounded-lg bg-stone-100 px-3 py-2 text-sm text-ink-700/60">Thinking…</div>
          </div>
        )}
      </div>

      <form onSubmit={submit} className="flex items-center gap-2 border-t border-stone-200 p-2">
        {recognition.isSupported && (
          <button
            type="button"
            onClick={() => (recognition.isListening ? recognition.stop() : recognition.start())}
            disabled={isSending}
            aria-label={recognition.isListening ? 'Stop listening' : 'Ask by voice'}
            aria-pressed={recognition.isListening}
            className={clsx(
              'flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition-colors',
              recognition.isListening ? 'animate-pulse bg-danger-600 text-white' : 'bg-stone-100 text-ink-700 hover:bg-stone-200',
            )}
          >
            <Mic className="h-4 w-4" />
          </button>
        )}
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder={recognition.isListening ? 'Listening…' : 'Ask about a property…'}
          className="flex-1 rounded-full border border-stone-200 px-3 py-2 text-sm outline-none focus:border-trust-500"
        />
        <Button type="submit" size="sm" disabled={!draft.trim() || isSending} aria-label="Send">
          <Send className="h-4 w-4" />
        </Button>
      </form>
    </Card>
  )
}

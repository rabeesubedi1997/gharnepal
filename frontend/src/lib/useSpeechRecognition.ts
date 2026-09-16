import { useCallback, useEffect, useRef, useState } from 'react'

// Not yet in TypeScript's DOM lib — declared narrowly for just what we use.
interface SpeechRecognitionResultLike {
  isFinal: boolean
  0: { transcript: string }
}
interface SpeechRecognitionEventLike extends Event {
  results: ArrayLike<SpeechRecognitionResultLike>
}
interface SpeechRecognitionLike extends EventTarget {
  lang: string
  interimResults: boolean
  continuous: boolean
  start: () => void
  stop: () => void
  onresult: ((event: SpeechRecognitionEventLike) => void) | null
  onend: (() => void) | null
  onerror: ((event: Event) => void) | null
}

declare global {
  interface Window {
    SpeechRecognition?: new () => SpeechRecognitionLike
    webkitSpeechRecognition?: new () => SpeechRecognitionLike
  }
}

/** Browser-native speech-to-text (Web Speech API) — free, no external
 * service, so it fits the assistant's zero-API-cost design (see
 * feedback-no-paid-ai-apis in project memory). Chrome/Edge/Safari support
 * it; Firefox doesn't — callers should hide the mic button entirely when
 * `isSupported` is false rather than show a control that can't work. */
export function useSpeechRecognition(onResult: (transcript: string) => void) {
  const [isListening, setIsListening] = useState(false)
  const recognitionRef = useRef<SpeechRecognitionLike | null>(null)
  const onResultRef = useRef(onResult)
  useEffect(() => {
    onResultRef.current = onResult
  })

  const Recognition = typeof window !== 'undefined' ? (window.SpeechRecognition ?? window.webkitSpeechRecognition) : undefined
  const isSupported = !!Recognition

  useEffect(() => () => recognitionRef.current?.stop(), [])

  const start = useCallback(() => {
    if (!Recognition || isListening) return

    const recognition = new Recognition()
    // Best zero-config default: whatever language the browser/OS is set to
    // — there's no reliable way to know ahead of time whether the next
    // utterance will be English or Nepali.
    recognition.lang = navigator.language || 'en-US'
    recognition.interimResults = false
    recognition.continuous = false
    recognition.onresult = (event) => {
      const transcript = Array.from(event.results)
        .map((result) => result[0].transcript)
        .join(' ')
        .trim()
      if (transcript) onResultRef.current(transcript)
    }
    recognition.onend = () => setIsListening(false)
    recognition.onerror = () => setIsListening(false)

    recognitionRef.current = recognition
    setIsListening(true)
    recognition.start()
  }, [Recognition, isListening])

  const stop = useCallback(() => {
    recognitionRef.current?.stop()
    setIsListening(false)
  }, [])

  return { isSupported, isListening, start, stop }
}

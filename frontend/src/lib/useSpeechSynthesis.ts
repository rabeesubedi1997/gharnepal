import { useCallback, useEffect, useState } from 'react'

const ENABLED_KEY = 'gharnepal:assistant:speak-replies'

/** Browser-native text-to-speech (Web Speech API) — free, no external
 * service. Voice availability/quality for Nepali varies by OS/browser, so
 * this degrades silently to whatever default voice is installed rather
 * than failing when a Nepali voice isn't available. */
export function useSpeechSynthesis() {
  const isSupported = typeof window !== 'undefined' && 'speechSynthesis' in window

  const [enabled, setEnabledState] = useState(() => {
    try {
      return isSupported && localStorage.getItem(ENABLED_KEY) === '1'
    } catch {
      return false
    }
  })

  useEffect(() => {
    if (!enabled && isSupported) window.speechSynthesis.cancel()
  }, [enabled, isSupported])

  const setEnabled = useCallback((value: boolean) => {
    setEnabledState(value)
    try {
      localStorage.setItem(ENABLED_KEY, value ? '1' : '0')
    } catch {
      // best-effort only — worst case the preference doesn't persist
    }
  }, [])

  const speak = useCallback(
    (text: string) => {
      if (!isSupported || !enabled || !text.trim()) return
      window.speechSynthesis.cancel()
      const utterance = new SpeechSynthesisUtterance(text)
      // Devanagari script needs a Nepali voice hint; Romanized Nepali and
      // English both read fine under an English voice.
      utterance.lang = /[ऀ-ॿ]/.test(text) ? 'ne-NP' : 'en-US'
      window.speechSynthesis.speak(utterance)
    },
    [isSupported, enabled],
  )

  return { isSupported, enabled, setEnabled, speak }
}

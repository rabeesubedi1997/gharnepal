import { useEffect, useRef } from 'react'

declare global {
  interface Window {
    grecaptcha?: {
      render: (
        container: HTMLElement,
        params: { sitekey: string; callback: (token: string) => void; 'expired-callback'?: () => void },
      ) => number
      reset: (widgetId?: number) => void
    }
    onRecaptchaApiLoad?: () => void
  }
}

let scriptLoadPromise: Promise<void> | null = null

function loadRecaptchaScript(): Promise<void> {
  if (window.grecaptcha) return Promise.resolve()
  if (scriptLoadPromise) return scriptLoadPromise
  scriptLoadPromise = new Promise((resolve) => {
    window.onRecaptchaApiLoad = () => resolve()
    const script = document.createElement('script')
    script.src = 'https://www.google.com/recaptcha/api.js?onload=onRecaptchaApiLoad&render=explicit'
    script.async = true
    script.defer = true
    document.head.appendChild(script)
  })
  return scriptLoadPromise
}

/** Google reCAPTCHA v2 checkbox — only ever rendered when the admin has actually configured and enabled it (see useCaptchaConfig). */
export function Recaptcha({ siteKey, onVerify }: { siteKey: string; onVerify: (token: string | null) => void }) {
  const containerRef = useRef<HTMLDivElement>(null)
  // A ref, not a dependency, so a parent passing a fresh onVerify each
  // render doesn't re-mount the widget.
  const onVerifyRef = useRef(onVerify)
  onVerifyRef.current = onVerify

  useEffect(() => {
    let cancelled = false
    loadRecaptchaScript().then(() => {
      if (cancelled || !containerRef.current || !window.grecaptcha) return
      window.grecaptcha.render(containerRef.current, {
        sitekey: siteKey,
        callback: (token) => onVerifyRef.current(token),
        'expired-callback': () => onVerifyRef.current(null),
      })
    })
    return () => {
      cancelled = true
    }
  }, [siteKey])

  return <div ref={containerRef} />
}

import { useCallback, useEffect, useState } from 'react'

export type UnitSystem = 'traditional' | 'metric'

const KEY = 'gharnepal:unit-system'

/** Nepal's property market quotes area/price in traditional units (Aana,
 * Ropani, Kattha, Dhur) far more often than square feet — this is a
 * persisted site-wide preference for which one to lead with wherever both
 * are shown, not a per-page toggle. Defaults to traditional since that's
 * how virtually every real listing in this market is actually priced. */
export function useUnitSystem() {
  const [unitSystem, setUnitSystemState] = useState<UnitSystem>(() => {
    try {
      const stored = localStorage.getItem(KEY)
      return stored === 'metric' ? 'metric' : 'traditional'
    } catch {
      return 'traditional'
    }
  })

  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === KEY) setUnitSystemState(e.newValue === 'metric' ? 'metric' : 'traditional')
    }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])

  const setUnitSystem = useCallback((value: UnitSystem) => {
    setUnitSystemState(value)
    try {
      localStorage.setItem(KEY, value)
    } catch {
      // best-effort only — worst case the preference doesn't persist
    }
  }, [])

  return { unitSystem, setUnitSystem }
}

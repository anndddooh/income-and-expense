import { useCallback, useEffect, useState } from 'react'
import type { State } from '@/components/StateIndicator'

const DEFAULT_SELECTED: State[] = [0, 1, 2]

function read(key: string): State[] {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return DEFAULT_SELECTED
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return DEFAULT_SELECTED
    const valid = parsed.filter(
      (v): v is State => v === 0 || v === 1 || v === 2,
    )
    return valid
  } catch {
    return DEFAULT_SELECTED
  }
}

export function useStoredStateFilter(
  key: string,
): [State[], (next: State[]) => void] {
  const [selected, setSelected] = useState<State[]>(() => read(key))

  useEffect(() => {
    try {
      localStorage.setItem(key, JSON.stringify(selected))
    } catch {
      // ignore (quota exceeded等)
    }
  }, [key, selected])

  const update = useCallback((next: State[]) => setSelected(next), [])

  return [selected, update]
}

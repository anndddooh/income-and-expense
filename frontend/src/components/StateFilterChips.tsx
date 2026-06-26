import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'
import type { State } from '@/components/StateIndicator'

const ALL_STATES: { state: State; label: string }[] = [
  { state: 0, label: '未定' },
  { state: 1, label: '確定' },
  { state: 2, label: '完了' },
]

function chipClass(state: State, active: boolean): string {
  if (!active) {
    return 'bg-transparent text-muted-foreground border-input hover:bg-accent'
  }
  switch (state) {
    case 0:
      return 'bg-amber-100 text-amber-900 border-amber-200 hover:bg-amber-100'
    case 1:
      return 'bg-blue-100 text-blue-900 border-blue-200 hover:bg-blue-100'
    case 2:
      return 'bg-muted text-muted-foreground border-transparent hover:bg-muted'
  }
}

export function StateFilterChips({
  selected,
  onChange,
}: {
  selected: State[]
  onChange: (next: State[]) => void
}) {
  const toggle = (s: State) => {
    const set = new Set(selected)
    if (set.has(s)) set.delete(s)
    else set.add(s)
    onChange(Array.from(set).sort((a, b) => a - b) as State[])
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="text-xs text-muted-foreground">状態:</span>
      {ALL_STATES.map(({ state, label }) => {
        const active = selected.includes(state)
        return (
          <button
            key={state}
            type="button"
            onClick={() => toggle(state)}
            aria-pressed={active}
            className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring rounded-full"
          >
            <Badge variant="outline" className={cn('cursor-pointer', chipClass(state, active))}>
              {label}
            </Badge>
          </button>
        )
      })}
    </div>
  )
}

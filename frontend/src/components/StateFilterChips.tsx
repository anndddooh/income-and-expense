import { STATE_META, type State } from '@/components/StateIndicator'

const ALL_STATES: State[] = [0, 1, 2]

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
      <span className="text-[12.5px] text-muted-foreground">状態:</span>
      {ALL_STATES.map((state) => {
        const { label, color, rgb } = STATE_META[state]
        const active = selected.includes(state)
        return (
          <button
            key={state}
            type="button"
            onClick={() => toggle(state)}
            aria-pressed={active}
            className="cursor-pointer rounded-full px-[13px] py-[5px] text-[12px] font-bold whitespace-nowrap transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
            style={
              active
                ? {
                    color,
                    background: `rgba(${rgb}, 0.16)`,
                    border: `1px solid rgba(${rgb}, 0.4)`,
                  }
                : {
                    color: 'var(--muted-foreground)',
                    background: 'transparent',
                    border: '1px solid var(--input)',
                  }
            }
          >
            {label}
          </button>
        )
      })}
    </div>
  )
}

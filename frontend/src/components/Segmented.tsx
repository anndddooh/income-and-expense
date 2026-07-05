import { cn } from '@/lib/utils'

export type SegmentedOption<T extends string> = {
  value: T
  label: string
  /** アクティブ時の文字色（状態セグメント用）。未指定なら primary-strong。 */
  activeColor?: string
}

export function Segmented<T extends string>({
  options,
  value,
  onChange,
  className,
  size = 'md',
}: {
  options: SegmentedOption<T>[]
  value: T
  onChange: (value: T) => void
  className?: string
  size?: 'sm' | 'md'
}) {
  return (
    <div
      className={cn(
        'inline-flex w-fit rounded-full bg-segment-track p-[3px]',
        className,
      )}
    >
      {options.map((o) => {
        const active = o.value === value
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            className={cn(
              'rounded-full font-bold whitespace-nowrap transition-colors',
              size === 'sm' ? 'px-3.5 py-[5px] text-[12.5px]' : 'px-[18px] py-[7px] text-[13px]',
              active
                ? 'bg-card shadow-[0_1px_4px_rgba(0,0,0,0.06)]'
                : 'text-muted-foreground',
            )}
            style={active ? { color: o.activeColor ?? 'var(--primary-strong)' } : undefined}
          >
            {o.label}
          </button>
        )
      })}
    </div>
  )
}

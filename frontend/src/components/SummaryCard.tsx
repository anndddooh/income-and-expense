import { cn } from '@/lib/utils'

export default function SummaryCard({
  label,
  value,
  valueClassName,
}: {
  label: string
  value: string
  valueClassName?: string
}) {
  return (
    <div className="rounded-card-sm border border-border bg-card px-[22px] py-[18px]">
      <div className="text-[13px] font-medium text-muted-foreground">{label}</div>
      <div
        className={cn(
          'mt-1.5 text-[26px] font-extrabold tabular-nums',
          valueClassName,
        )}
      >
        {value}
      </div>
    </div>
  )
}

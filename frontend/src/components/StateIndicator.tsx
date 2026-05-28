import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export type State = 0 | 1 | 2

/**
 * TableRowに付ける左端カラーバー用のクラス。
 * tr に border-l を当てても効かない環境があるので、
 * 先頭セルに border-l-4 と色を当てる想定。
 */
export function stateBarClass(state: State): string {
  switch (state) {
    case 0:
      return 'border-l-4 border-l-amber-400'
    case 1:
      return 'border-l-4 border-l-blue-500'
    case 2:
      return 'border-l-4 border-l-muted-foreground/40'
  }
}

/**
 * ドットだけの軽量表示(ダッシュボードなど狭い場所用)。
 */
export function StateDot({
  state,
  className,
}: {
  state: State
  className?: string
}) {
  const color =
    state === 0
      ? 'bg-amber-400'
      : state === 1
        ? 'bg-blue-500'
        : 'bg-muted-foreground/40'
  return (
    <span
      aria-hidden
      className={cn('inline-block size-2 rounded-full', color, className)}
    />
  )
}

/**
 * 状態をテキスト付きの色バッジで表示。
 */
export function StateBadge({
  state,
  label,
}: {
  state: State
  label: string
}) {
  const cls =
    state === 0
      ? 'bg-amber-100 text-amber-900 border-amber-200 hover:bg-amber-100'
      : state === 1
        ? 'bg-blue-100 text-blue-900 border-blue-200 hover:bg-blue-100'
        : 'bg-muted text-muted-foreground border-transparent hover:bg-muted'
  return (
    <Badge variant="outline" className={cls}>
      {label}
    </Badge>
  )
}

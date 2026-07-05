import type { CSSProperties } from 'react'
import { cn } from '@/lib/utils'

export type State = 0 | 1 | 2

/** 状態ごとの色（「ゆとり」テーマ）。rgb は不透明度付き背景/枠に使う。 */
export const STATE_META: Record<State, { label: string; color: string; rgb: string }> = {
  0: { label: '未定', color: 'var(--state-undecided)', rgb: '176,132,48' },
  1: { label: '確定', color: 'var(--state-confirmed)', rgb: '100,121,143' },
  2: { label: '完了', color: 'var(--state-done)', rgb: '82,121,107' },
}

/**
 * 旧: 左端カラーバー用クラス。新デザインでは状態バッジに一本化したため無効化。
 * 呼び出し側の互換のため空文字を返す。
 */
export function stateBarClass(_state: State): string {
  return ''
}

/** ドットだけの軽量表示(ダッシュボードなど狭い場所用)。 */
export function StateDot({
  state,
  className,
}: {
  state: State
  className?: string
}) {
  const { color } = STATE_META[state]
  return (
    <span
      aria-hidden
      className={cn('inline-block size-2 rounded-full', className)}
      style={{ background: color }}
    />
  )
}

/** 状態をテキスト付きの色ピルで表示。 */
export function StateBadge({
  state,
  label,
  style,
}: {
  state: State
  label: string
  style?: CSSProperties
}) {
  const { color, rgb } = STATE_META[state]
  return (
    <span
      className="inline-flex items-center rounded-full px-2.5 py-[3px] text-[11.5px] font-bold whitespace-nowrap"
      style={{ color, background: `rgba(${rgb}, 0.15)`, ...style }}
    >
      {label}
    </span>
  )
}

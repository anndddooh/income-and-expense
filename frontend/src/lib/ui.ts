/**
 * 「ゆとり」テーマ共通のスタイルクラス。
 * ボタンは完全な pill、カードは radius 20px・枠線のみ（影なし）。
 */

/** 主ボタン（honey pill） */
export const pillPrimary =
  'inline-flex h-[38px] items-center justify-center gap-1.5 rounded-full bg-primary px-[18px] text-[13.5px] font-bold text-primary-foreground whitespace-nowrap transition-colors hover:bg-primary/90 disabled:pointer-events-none disabled:opacity-50'

/** アウトラインボタン（枠 1.5px accent、文字 primary-strong） */
export const pillOutline =
  'inline-flex h-[38px] items-center justify-center gap-1.5 rounded-full border-[1.5px] border-accent bg-card px-[18px] text-[13.5px] font-bold text-primary-strong whitespace-nowrap transition-colors hover:bg-primary-soft/40 disabled:pointer-events-none disabled:opacity-50'

/** キャンセル等の控えめアウトライン（枠 input、文字 muted-foreground-2） */
export const pillCancel =
  'inline-flex h-[38px] items-center justify-center gap-1.5 rounded-full border-[1.5px] border-input bg-card px-[18px] text-[13.5px] font-bold text-muted-foreground-2 whitespace-nowrap transition-colors hover:bg-secondary/60 disabled:pointer-events-none disabled:opacity-50'

/** 小さめアウトライン pill（一覧の「編集」など） */
export const pillOutlineSm =
  'inline-flex h-8 items-center justify-center gap-1 rounded-full border-[1.5px] border-accent bg-card px-3.5 text-[12.5px] font-bold text-primary-strong whitespace-nowrap transition-colors hover:bg-primary-soft/40 disabled:pointer-events-none disabled:opacity-50'

/** カード（radius 20px、枠線のみ） */
export const card = 'rounded-card border border-border bg-card'

/** 小カード（radius 16px） */
export const cardSm = 'rounded-card-sm border border-border bg-card'

/** テーブルを収めるカード（角丸クリップ） */
export const tableCard = 'overflow-hidden rounded-card border border-border bg-card'

/** 入力欄（高さ 42px・radius 12px・背景 #fff） */
export const inputField =
  'h-[42px] rounded-input border border-input bg-white px-3.5 text-[13.5px] text-foreground placeholder:text-placeholder focus-visible:border-accent focus-visible:outline-none'

/** フォームのラベル */
export const fieldLabel = 'text-[13px] font-bold text-foreground'

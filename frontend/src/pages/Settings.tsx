import { LogOut, PiggyBank, ReceiptText } from 'lucide-react'
import type { ReactNode } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import PageHeader from '@/components/PageHeader'
import { card } from '@/lib/ui'
import { clearTokens } from '@/lib/auth'

const ITEMS = [
  {
    label: 'デフォルト収入',
    description: '毎月自動で追加する収入のテンプレートを管理します',
    to: '/settings/default-incomes',
    icon: <PiggyBank className="size-5" />,
    tileBg: 'rgba(110,154,84,0.15)',
    tileColor: 'var(--income)',
  },
  {
    label: 'デフォルト支出',
    description: '毎月自動で追加する支出のテンプレートを管理します',
    to: '/settings/default-expenses',
    icon: <ReceiptText className="size-5" />,
    tileBg: 'rgba(209,161,60,0.18)',
    tileColor: 'var(--primary-strong)',
  },
]

function IconTile({
  bg,
  color,
  children,
}: {
  bg: string
  color: string
  children: ReactNode
}) {
  return (
    <span
      className="flex size-10 shrink-0 items-center justify-center rounded-[12px]"
      style={{ background: bg, color }}
    >
      {children}
    </span>
  )
}

export default function Settings() {
  const navigate = useNavigate()

  return (
    <div className="max-w-2xl">
      <PageHeader title="設定" />
      <div className="grid gap-3.5">
        {ITEMS.map((it) => (
          <Link
            key={it.to}
            to={it.to}
            className={`${card} flex items-start gap-3.5 p-[22px] transition-colors hover:bg-primary-soft/30`}
          >
            <IconTile bg={it.tileBg} color={it.tileColor}>
              {it.icon}
            </IconTile>
            <div className="flex-1">
              <div className="text-[15px] font-extrabold">{it.label}</div>
              <div className="mt-[3px] text-[13px] text-muted-foreground">
                {it.description}
              </div>
            </div>
            <span className="text-[16px] text-accent">›</span>
          </Link>
        ))}

        <button
          type="button"
          onClick={() => {
            clearTokens()
            navigate('/login', { replace: true })
          }}
          className={`${card} flex items-center gap-3.5 p-[22px] text-left transition-colors hover:bg-destructive/5`}
        >
          <IconTile bg="rgba(179,88,76,0.12)" color="var(--expense)">
            <LogOut className="size-5" />
          </IconTile>
          <div className="text-[15px] font-extrabold text-expense">
            ログアウト
          </div>
        </button>
      </div>
    </div>
  )
}

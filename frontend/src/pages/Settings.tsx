import { PiggyBank, ReceiptText } from 'lucide-react'
import { Link } from 'react-router-dom'
import PageHeader from '@/components/PageHeader'
import { Card, CardContent } from '@/components/ui/card'

const ITEMS = [
  {
    label: 'デフォルト収入',
    description: '毎月自動で追加する収入のテンプレートを管理します',
    to: '/settings/default-incomes',
    icon: <PiggyBank className="size-5" />,
  },
  {
    label: 'デフォルト支出',
    description: '毎月自動で追加する支出のテンプレートを管理します',
    to: '/settings/default-expenses',
    icon: <ReceiptText className="size-5" />,
  },
]

export default function Settings() {
  return (
    <>
      <PageHeader title="設定" />
      <div className="grid gap-3 sm:grid-cols-2">
        {ITEMS.map((it) => (
          <Link key={it.to} to={it.to} className="block">
            <Card className="transition-colors hover:bg-accent">
              <CardContent className="flex items-start gap-3 pt-6">
                <div className="text-muted-foreground">{it.icon}</div>
                <div>
                  <div className="font-semibold">{it.label}</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    {it.description}
                  </div>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </>
  )
}

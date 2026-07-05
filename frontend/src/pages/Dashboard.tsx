import { useQuery } from '@tanstack/react-query'
import { Link, useParams } from 'react-router-dom'
import PageHeader from '@/components/PageHeader'
import TrendChart from '@/components/TrendChart'
import { card, cardSm, pillOutline, pillPrimary } from '@/lib/ui'
import { cn } from '@/lib/utils'
import { fetchBalance } from '@/api/balance'
import { fetchExpenses } from '@/api/expenses'
import { fetchIncomes } from '@/api/incomes'
import { fetchAccountRequire } from '@/api/requires'
import { fetchTrends } from '@/api/trends'
import { todayYearMonth } from '@/util/date'

export default function Dashboard() {
  const params = useParams<{ year?: string; month?: string }>()
  const now = todayYearMonth()
  const year = params.year ? Number(params.year) : now.year
  const month = params.month ? Number(params.month) : now.month

  const incomesQ = useQuery({
    queryKey: ['incomes', year, month],
    queryFn: () => fetchIncomes(year, month),
  })
  const expensesQ = useQuery({
    queryKey: ['expenses', year, month],
    queryFn: () => fetchExpenses(year, month),
  })
  const balanceQ = useQuery({
    queryKey: ['balance', year, month],
    queryFn: () => fetchBalance(year, month),
  })
  const requireQ = useQuery({
    queryKey: ['account-require', year, month],
    queryFn: () => fetchAccountRequire(year, month),
  })
  const trendsQ = useQuery({
    queryKey: ['trends', year, month, 12],
    queryFn: () => fetchTrends(12, year, month),
  })

  const incomes = incomesQ.data?.results ?? []
  const expenses = expensesQ.data?.results ?? []
  const incomeTotal = incomes.reduce((s, i) => s + i.amount, 0)
  const expenseTotal = expenses.reduce((s, i) => s + i.amount, 0)
  const net = incomeTotal - expenseTotal
  const balanceSum = balanceQ.data?.balance_sum ?? 0
  const prevBalance = incomesQ.data?.prev_balance ?? 0
  const insufficient = requireQ.data?.insufficient_sum ?? 0

  const recent = [
    ...incomes.map((r) => ({
      id: `i-${r.id}`,
      pay_date: r.pay_date,
      name: r.name,
      kind: '収入' as const,
      amount: r.amount,
    })),
    ...expenses.map((r) => ({
      id: `e-${r.id}`,
      pay_date: r.pay_date,
      name: r.name,
      kind: '支出' as const,
      amount: r.amount,
    })),
  ]
    .sort((a, b) => b.pay_date.localeCompare(a.pay_date))
    .slice(0, 8)

  return (
    <>
      <PageHeader title="ホーム" description={`${month}月のサマリ`} />

      {/* hero + KPI */}
      <div className="grid gap-4 lg:grid-cols-[1.5fr_1fr]">
        <div className={cn(card, 'p-7')}>
          <div className="text-[14px] font-medium text-muted-foreground">
            {month}月の収支
          </div>
          <div
            className="mt-1.5 text-[44px] leading-none font-extrabold tabular-nums"
            style={{ color: net >= 0 ? 'var(--income)' : 'var(--expense)' }}
          >
            {net >= 0 ? '＋' : '−'}¥{Math.abs(net).toLocaleString()}
          </div>
          <div className="mt-2.5 flex gap-6 text-[13px] text-muted-foreground tabular-nums">
            <span>
              収入{' '}
              <span className="font-bold text-foreground">
                ¥{incomeTotal.toLocaleString()}
              </span>
            </span>
            <span>
              支出{' '}
              <span className="font-bold text-foreground">
                ¥{expenseTotal.toLocaleString()}
              </span>
            </span>
          </div>
          <div className="mt-[22px] flex flex-wrap gap-2.5">
            <Link to={`/expenses/${year}/${month}/new`} className={pillPrimary}>
              ＋ 支出を追加
            </Link>
            <Link to={`/incomes/${year}/${month}/new`} className={pillOutline}>
              ＋ 収入を追加
            </Link>
          </div>
        </div>

        <div className="grid content-start gap-3">
          <Kpi
            label="口座残高合計"
            value={`¥${balanceSum.toLocaleString()}`}
          />
          <Kpi label="前月繰越" value={`¥${prevBalance.toLocaleString()}`} />
          <Kpi
            label="不足額"
            value={`¥${insufficient.toLocaleString()}`}
            valueColor={insufficient > 0 ? 'var(--expense)' : 'var(--income)'}
          />
        </div>
      </div>

      {/* chart + recent */}
      <div className="mt-4 grid gap-4 lg:grid-cols-[3fr_2fr]">
        <div className={cn(card, 'p-[22px]')}>
          <div className="flex items-baseline justify-between">
            <span className="text-[15px] font-extrabold">月ごとのながれ</span>
            <div className="flex gap-3.5">
              <Legend color="var(--income)" label="収入" />
              <Legend color="var(--accent)" label="支出" />
            </div>
          </div>
          <div className="mt-2">
            {trendsQ.isLoading ? (
              <p className="py-16 text-center text-[13px] text-muted-foreground">
                読み込み中...
              </p>
            ) : trendsQ.data ? (
              <TrendChart data={trendsQ.data.months} />
            ) : null}
          </div>
        </div>

        <div className={cn(card, 'py-[22px]')}>
          <div className="px-[22px] pb-2 text-[15px] font-extrabold">
            最近の記帳
          </div>
          {recent.length === 0 ? (
            <p className="py-10 text-center text-[13px] text-muted-foreground">
              データがありません
            </p>
          ) : (
            recent.map((r) => (
              <div
                key={r.id}
                className="flex items-center gap-3 border-t border-row-separator px-[22px] py-2"
              >
                <div className="min-w-0 flex-1">
                  <div className="truncate text-[13.5px] font-medium">
                    {r.name}
                  </div>
                  <div className="text-[11px] text-muted-foreground tabular-nums">
                    {r.pay_date}
                  </div>
                </div>
                <span
                  className="text-[13.5px] font-bold tabular-nums"
                  style={{
                    color:
                      r.kind === '収入' ? 'var(--income)' : 'var(--foreground)',
                  }}
                >
                  {r.kind === '収入' ? '＋' : '−'}¥{r.amount.toLocaleString()}
                </span>
              </div>
            ))
          )}
        </div>
      </div>
    </>
  )
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 text-[11.5px] text-muted-foreground-2">
      <span
        className="size-[9px] rounded-full"
        style={{ background: color }}
      />
      {label}
    </span>
  )
}

function Kpi({
  label,
  value,
  valueColor,
}: {
  label: string
  value: string
  valueColor?: string
}) {
  return (
    <div
      className={cn(
        cardSm,
        'flex items-center justify-between px-5 py-3.5',
      )}
    >
      <span className="text-[13px] font-medium text-muted-foreground">
        {label}
      </span>
      <span
        className="text-[19px] font-extrabold tabular-nums"
        style={valueColor ? { color: valueColor } : undefined}
      >
        {value}
      </span>
    </div>
  )
}

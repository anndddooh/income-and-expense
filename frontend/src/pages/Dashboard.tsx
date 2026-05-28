import { useQuery } from '@tanstack/react-query'
import {
  AlertTriangle,
  ArrowDownCircle,
  ArrowUpCircle,
  Plus,
  Wallet,
} from 'lucide-react'
import { Link, useParams } from 'react-router-dom'
import PageHeader from '@/components/PageHeader'
import { StateDot, type State } from '@/components/StateIndicator'
import TrendChart from '@/components/TrendChart'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
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
  const balanceSum = balanceQ.data?.balance_sum ?? 0
  const insufficient = requireQ.data?.insufficient_sum ?? 0

  const recent = [
    ...incomes.map((r) => ({
      id: `i-${r.id}`,
      pay_date: r.pay_date,
      name: r.name,
      method: r.method_name,
      kind: '収入' as const,
      amount: r.amount,
      state: r.state as State,
    })),
    ...expenses.map((r) => ({
      id: `e-${r.id}`,
      pay_date: r.pay_date,
      name: r.name,
      method: r.method_name,
      kind: '支出' as const,
      amount: r.amount,
      state: r.state as State,
    })),
  ]
    .sort((a, b) => b.pay_date.localeCompare(a.pay_date))
    .slice(0, 8)

  return (
    <>
      <PageHeader
        title="ダッシュボード"
        description={`${year}年${month}月のサマリ`}
        actions={
          <>
            <Button asChild variant="outline" size="sm">
              <Link to={`/incomes/${year}/${month}/new`}>
                <Plus className="size-4" />
                収入を追加
              </Link>
            </Button>
            <Button asChild size="sm">
              <Link to={`/expenses/${year}/${month}/new`}>
                <Plus className="size-4" />
                支出を追加
              </Link>
            </Button>
          </>
        }
      />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Kpi
          label="今月の収入"
          value={`¥${incomeTotal.toLocaleString()}`}
          icon={<ArrowUpCircle className="size-4 text-chart-1" />}
        />
        <Kpi
          label="今月の支出"
          value={`¥${expenseTotal.toLocaleString()}`}
          icon={<ArrowDownCircle className="size-4 text-chart-2" />}
        />
        <Kpi
          label="口座残高合計"
          value={`¥${balanceSum.toLocaleString()}`}
          icon={<Wallet className="size-4" />}
        />
        <Kpi
          label="不足額合計"
          value={`¥${insufficient.toLocaleString()}`}
          valueClassName={
            insufficient > 0 ? 'text-destructive' : 'text-green-600'
          }
          icon={
            <AlertTriangle
              className={cn(
                'size-4',
                insufficient > 0 ? 'text-destructive' : 'text-muted-foreground'
              )}
            />
          }
        />
      </div>

      <div className="mt-6 grid gap-6 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>月次推移 (直近12か月)</CardTitle>
            <CardDescription>収入と支出の比較</CardDescription>
          </CardHeader>
          <CardContent>
            {trendsQ.isLoading ? (
              <p className="text-sm text-muted-foreground">読み込み中...</p>
            ) : trendsQ.data ? (
              <TrendChart data={trendsQ.data.months} />
            ) : null}
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>最近の取引</CardTitle>
            <CardDescription>
              当月の収支から最新 {recent.length} 件
            </CardDescription>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>日付</TableHead>
                  <TableHead>名称</TableHead>
                  <TableHead>種別</TableHead>
                  <TableHead className="text-right">金額</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recent.map((r) => (
                  <TableRow key={r.id}>
                    <TableCell className="tabular-nums text-xs">
                      {r.pay_date}
                    </TableCell>
                    <TableCell className="truncate max-w-32">
                      <span className="inline-flex items-center gap-1.5">
                        <StateDot state={r.state} />
                        {r.name}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span
                        className={cn(
                          'text-xs font-medium',
                          r.kind === '収入'
                            ? 'text-chart-1'
                            : 'text-chart-2'
                        )}
                      >
                        {r.kind}
                      </span>
                    </TableCell>
                    <TableCell className="text-right tabular-nums">
                      ¥{r.amount.toLocaleString()}
                    </TableCell>
                  </TableRow>
                ))}
                {recent.length === 0 && (
                  <TableRow>
                    <TableCell
                      colSpan={4}
                      className="text-center text-muted-foreground"
                    >
                      データがありません
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </>
  )
}

function Kpi({
  label,
  value,
  valueClassName,
  icon,
}: {
  label: string
  value: string
  valueClassName?: string
  icon?: React.ReactNode
}) {
  return (
    <Card>
      <CardHeader className="pb-2 flex flex-row items-start justify-between space-y-0">
        <CardDescription>{label}</CardDescription>
        {icon}
      </CardHeader>
      <CardContent>
        <div className={cn('text-2xl font-semibold tabular-nums', valueClassName)}>
          {value}
        </div>
      </CardContent>
    </Card>
  )
}

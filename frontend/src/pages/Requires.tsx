import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
import { Segmented } from '@/components/Segmented'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { cardSm, pillOutlineSm, tableCard } from '@/lib/ui'
import { cn } from '@/lib/utils'
import {
  fetchAccountRequire,
  fetchMethodRequire,
  methodDone,
  type MethodRequireRow,
} from '@/api/requires'

type Tab = 'account' | 'method'

export default function Requires() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
  const [searchParams, setSearchParams] = useSearchParams()
  const tab: Tab = searchParams.get('tab') === 'method' ? 'method' : 'account'

  const setTab = (t: Tab) => {
    setSearchParams(t === 'account' ? {} : { tab: t }, { replace: true })
  }

  return (
    <>
      <PageHeader
        title="必要額"
        description={`${year}年${month}月 · 月内に必要になるお金の見通し`}
        actions={
          <Segmented<Tab>
            value={tab}
            onChange={setTab}
            options={[
              { value: 'account', label: '口座別' },
              { value: 'method', label: '支払方法別' },
            ]}
          />
        }
      />

      {tab === 'account' ? (
        <AccountView year={year} month={month} />
      ) : (
        <MethodView year={year} month={month} />
      )}
    </>
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
    <div className={cn(cardSm, 'px-[22px] py-[18px]')}>
      <div className="text-[13px] font-medium text-muted-foreground">{label}</div>
      <div
        className="mt-1.5 text-[26px] font-extrabold tabular-nums"
        style={valueColor ? { color: valueColor } : undefined}
      >
        {value}
      </div>
    </div>
  )
}

const headCell = 'text-[12px] font-bold text-muted-foreground'

function AccountView({ year, month }: { year: number; month: number }) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['account-require', year, month],
    queryFn: () => fetchAccountRequire(year, month),
  })

  if (isLoading) return <p className="text-muted-foreground">読み込み中...</p>
  if (error) return <p className="text-destructive">エラー: {String(error)}</p>
  if (!data) return null

  return (
    <>
      <div className="mb-4 grid gap-4 md:grid-cols-2">
        <Kpi label="必要額合計" value={`¥${data.require_sum.toLocaleString()}`} />
        <Kpi
          label="不足額合計"
          value={`¥${data.insufficient_sum.toLocaleString()}`}
          valueColor={data.insufficient_sum > 0 ? 'var(--expense)' : undefined}
        />
      </div>

      <div className={tableCard}>
        <Table>
          <TableHeader>
            <TableRow className="border-border hover:bg-transparent">
              <TableHead className={headCell}>ユーザー</TableHead>
              <TableHead className={headCell}>銀行</TableHead>
              <TableHead className={cn(headCell, 'text-right')}>残高</TableHead>
              <TableHead className={cn(headCell, 'text-right')}>必要額</TableHead>
              <TableHead className={cn(headCell, 'text-right')}>不足額</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.accounts.map((a) => (
              <TableRow
                key={a.id}
                className="border-row-separator text-[13.5px] hover:bg-transparent"
                style={
                  a.is_insufficient
                    ? { background: 'rgba(179,88,76,0.08)' }
                    : undefined
                }
              >
                <TableCell>{a.user}</TableCell>
                <TableCell className="font-bold">{a.bank}</TableCell>
                <TableCell className="text-right tabular-nums">
                  {a.formed_balance}
                </TableCell>
                <TableCell className="text-right tabular-nums">
                  {a.formed_require}
                </TableCell>
                <TableCell className="text-right tabular-nums">
                  {a.is_insufficient ? (
                    <span className="font-extrabold text-expense">
                      {a.formed_insufficient}
                    </span>
                  ) : (
                    '-'
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </>
  )
}

function MethodView({ year, month }: { year: number; month: number }) {
  const qc = useQueryClient()
  const key = ['method-require', year, month]
  const { data, isLoading, error } = useQuery({
    queryKey: key,
    queryFn: () => fetchMethodRequire(year, month),
  })
  const [target, setTarget] = useState<MethodRequireRow | null>(null)

  const doneMut = useMutation({
    mutationFn: (id: number) => methodDone(id, year, month),
    onSuccess: (d) => {
      toast.success(`${d.updated}件を完了にしました`)
      qc.invalidateQueries({ queryKey: key })
      setTarget(null)
    },
    onError: (e: unknown) => toast.error('失敗: ' + String(e)),
  })

  if (isLoading) return <p className="text-muted-foreground">読み込み中...</p>
  if (error) return <p className="text-destructive">エラー: {String(error)}</p>
  if (!data) return null

  return (
    <>
      <div className="mb-4 grid gap-4 md:grid-cols-2">
        <Kpi label="必要額合計" value={`¥${data.require_sum.toLocaleString()}`} />
      </div>

      <div className={tableCard}>
        <Table>
          <TableHeader>
            <TableRow className="border-border hover:bg-transparent">
              <TableHead className={headCell}>支払方法</TableHead>
              <TableHead className={cn(headCell, 'text-right')}>必要額</TableHead>
              <TableHead className={cn(headCell, 'w-32 text-right')}>操作</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.methods.map((row) => (
              <TableRow
                key={row.id}
                className="border-row-separator text-[13.5px] hover:bg-transparent"
              >
                <TableCell className="font-bold">{row.display_name}</TableCell>
                <TableCell className="text-right tabular-nums">
                  {row.formed_require}
                </TableCell>
                <TableCell className="text-right">
                  {row.require > 0 && (
                    <button
                      type="button"
                      className={pillOutlineSm}
                      onClick={() => setTarget(row)}
                    >
                      一括完了
                    </button>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <AlertDialog open={!!target} onOpenChange={(o) => !o && setTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>一括完了しますか?</AlertDialogTitle>
            <AlertDialogDescription>
              「{target?.display_name}」の今月の未完了支出をすべて完了にします。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>キャンセル</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => target && doneMut.mutate(target.id)}
              disabled={doneMut.isPending}
            >
              完了にする
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}

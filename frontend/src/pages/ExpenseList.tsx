import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
import { StateBadge, type State } from '@/components/StateIndicator'
import { StateFilterChips } from '@/components/StateFilterChips'
import { useStoredStateFilter } from '@/hooks/useStoredStateFilter'
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
import { pillOutline, pillPrimary, tableCard } from '@/lib/ui'
import { dayOf } from '@/util/date'
import {
  addDefaultExpenses,
  deleteExpense,
  fetchExpenses,
  type Expense,
} from '@/api/expenses'

export default function ExpenseList() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [deleting, setDeleting] = useState<Expense | null>(null)

  const key = ['expenses', year, month]
  const { data, isLoading, error } = useQuery({
    queryKey: key,
    queryFn: () => fetchExpenses(year, month),
  })
  const items = data?.results ?? []
  const balance = data?.balance ?? 0

  const [stateFilter, setStateFilter] = useStoredStateFilter(
    'inex.expenseList.stateFilter',
  )
  const visibleItems = items.filter((i) =>
    stateFilter.includes(i.state as State),
  )

  const delMut = useMutation({
    mutationFn: (id: number) => deleteExpense(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: key })
      setDeleting(null)
      toast.success('削除しました')
    },
    onError: (e: unknown) => toast.error('削除失敗: ' + extractError(e)),
  })

  const addDefMut = useMutation({
    mutationFn: () => addDefaultExpenses(year, month),
    onSuccess: (d) => {
      toast.success(`${d.added}件追加しました`)
      qc.invalidateQueries({ queryKey: key })
    },
    onError: (e: unknown) => toast.error('追加失敗: ' + extractError(e)),
  })

  const total = items.reduce((s, i) => s + i.amount, 0)

  return (
    <>
      <PageHeader
        title="支出"
        description={`${year}年${month}月 · ${items.length}件 · ¥${total.toLocaleString()}`}
        actions={
          <>
            <button
              type="button"
              className={pillOutline}
              onClick={() => addDefMut.mutate()}
              disabled={addDefMut.isPending}
            >
              ⟳ デフォルトから追加
            </button>
            <button
              type="button"
              className={pillPrimary}
              onClick={() => navigate(`/expenses/${year}/${month}/new`)}
            >
              ＋ 支出を追加
            </button>
          </>
        }
      />

      <div className="mb-3.5">
        <StateFilterChips selected={stateFilter} onChange={setStateFilter} />
      </div>

      <div className={tableCard}>
        <Table>
          <TableHeader>
            <TableRow className="border-border hover:bg-transparent">
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                支払日
              </TableHead>
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                名称
              </TableHead>
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                支払方法
              </TableHead>
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                口座
              </TableHead>
              <TableHead className="text-right text-[12px] font-bold text-muted-foreground">
                金額
              </TableHead>
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                状態
              </TableHead>
              <TableHead className="w-14 text-right text-[12px] font-bold text-muted-foreground">
                操作
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground">
                  読み込み中...
                </TableCell>
              </TableRow>
            )}
            {error && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-destructive">
                  エラー: {String(error)}
                </TableCell>
              </TableRow>
            )}
            {!isLoading && !error && items.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground">
                  データがありません
                </TableCell>
              </TableRow>
            )}
            {!isLoading && !error && items.length > 0 && visibleItems.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground">
                  フィルター条件に一致する支出はありません
                </TableCell>
              </TableRow>
            )}
            {visibleItems.map((i) => (
              <TableRow
                key={i.id}
                tabIndex={0}
                className="cursor-pointer border-row-separator text-[13.5px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                onClick={() =>
                  navigate(`/expenses/${year}/${month}/${i.id}/edit`)
                }
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    navigate(`/expenses/${year}/${month}/${i.id}/edit`)
                  }
                }}
              >
                <TableCell className="tabular-nums text-muted-foreground-2">
                  {dayOf(i.pay_date)}
                </TableCell>
                <TableCell className="font-bold">{i.name}</TableCell>
                <TableCell>{i.method_name}</TableCell>
                <TableCell className="text-[13px] text-muted-foreground">
                  {i.account.user} / {i.account.bank}
                </TableCell>
                <TableCell className="text-right font-bold tabular-nums">
                  {i.formed_amount}
                </TableCell>
                <TableCell>
                  <StateBadge state={i.state as State} label={i.state_label} />
                </TableCell>
                <TableCell className="text-right">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      setDeleting(i)
                    }}
                    aria-label="削除"
                    className="inline-flex size-7 items-center justify-center rounded-md transition-colors hover:bg-destructive/10"
                  >
                    <Trash2 className="size-[15px] text-destructive" />
                  </button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <div className="flex justify-end gap-7 bg-footer-bg px-[22px] py-3.5 text-[13px] text-muted-foreground">
          <span>
            当月支出{' '}
            <span className="font-extrabold text-foreground tabular-nums">
              ¥{total.toLocaleString()}
            </span>
          </span>
          <span>
            当月残高{' '}
            <span className="font-extrabold text-foreground tabular-nums">
              ¥{balance.toLocaleString()}
            </span>
          </span>
        </div>
      </div>

      <AlertDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>削除しますか?</AlertDialogTitle>
            <AlertDialogDescription>
              「{deleting?.name}」を削除します。この操作は取り消せません。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>キャンセル</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deleting && delMut.mutate(deleting.id)}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              削除
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}

function extractError(e: unknown): string {
  type AxiosLike = { response?: { data?: unknown }; message?: string }
  const ax = e as AxiosLike
  const data = ax?.response?.data
  if (Array.isArray(data)) return data.join(' ')
  if (typeof data === 'string') return data
  if (data && typeof data === 'object') {
    const record = data as Record<string, unknown>
    if (typeof record.detail === 'string') return record.detail
    return Object.values(record)
      .map((v) => (Array.isArray(v) ? v.join(' ') : String(v)))
      .join('\n')
  }
  return ax?.message ?? String(e)
}

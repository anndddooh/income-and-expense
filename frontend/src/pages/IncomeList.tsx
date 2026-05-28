import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Plus, RefreshCcw, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
import { StateBadge, stateBarClass, type State } from '@/components/StateIndicator'
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
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  addDefaultIncomes,
  deleteIncome,
  fetchIncomes,
} from '@/api/incomes'
import type { Income } from '@/api/types'

export default function IncomeList() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [deleting, setDeleting] = useState<Income | null>(null)

  const key = ['incomes', year, month]
  const { data, isLoading, error } = useQuery({
    queryKey: key,
    queryFn: () => fetchIncomes(year, month),
  })
  const incomes = data?.results ?? []
  const prevBalance = data?.prev_balance ?? 0

  const delMut = useMutation({
    mutationFn: (id: number) => deleteIncome(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: key })
      setDeleting(null)
      toast.success('削除しました')
    },
    onError: (e: unknown) => toast.error('削除失敗: ' + extractError(e)),
  })

  const addDefMut = useMutation({
    mutationFn: () => addDefaultIncomes(year, month),
    onSuccess: (d) => {
      toast.success(`${d.added}件追加しました`)
      qc.invalidateQueries({ queryKey: key })
    },
    onError: (e: unknown) => toast.error('追加失敗: ' + extractError(e)),
  })

  const total = incomes.reduce((s, i) => s + i.amount, 0)

  return (
    <>
      <PageHeader
        title="収入一覧"
        description={`${year}年${month}月`}
        actions={
          <>
            <Button
              variant="outline"
              size="sm"
              onClick={() => addDefMut.mutate()}
              disabled={addDefMut.isPending}
            >
              <RefreshCcw className="size-4" />
              デフォルトから追加
            </Button>
            <Button
              size="sm"
              onClick={() => navigate(`/incomes/${year}/${month}/new`)}
            >
              <Plus className="size-4" />
              新規作成
            </Button>
          </>
        }
      />

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>支払日</TableHead>
                <TableHead>名称</TableHead>
                <TableHead>支払方法</TableHead>
                <TableHead>口座</TableHead>
                <TableHead className="text-right">金額</TableHead>
                <TableHead>状態</TableHead>
                <TableHead className="w-16 text-right">操作</TableHead>
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
              {!isLoading && !error && incomes.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} className="text-center text-muted-foreground">
                    データがありません
                  </TableCell>
                </TableRow>
              )}
              {incomes.map((i) => (
                <TableRow
                  key={i.id}
                  tabIndex={0}
                  className="cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  onClick={() =>
                    navigate(`/incomes/${year}/${month}/${i.id}/edit`)
                  }
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      navigate(`/incomes/${year}/${month}/${i.id}/edit`)
                    }
                  }}
                >
                  <TableCell
                    className={`tabular-nums ${stateBarClass(i.state as State)}`}
                  >
                    {i.pay_date}
                  </TableCell>
                  <TableCell className="font-medium">{i.name}</TableCell>
                  <TableCell>{i.method_name}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {i.account.user} / {i.account.bank}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {i.formed_amount}
                  </TableCell>
                  <TableCell>
                    <StateBadge state={i.state as State} label={i.state_label} />
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={(e) => {
                        e.stopPropagation()
                        setDeleting(i)
                      }}
                      aria-label="削除"
                    >
                      <Trash2 className="size-4 text-destructive" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <div className="mt-4 space-y-1 text-sm text-muted-foreground">
        <div>前月残高: <span className="font-semibold text-foreground tabular-nums">¥{prevBalance.toLocaleString()}</span></div>
        <div>当月収入: <span className="font-semibold text-foreground tabular-nums">¥{total.toLocaleString()}</span>（{incomes.length}件）</div>
        <div>合計: <span className="font-semibold text-foreground tabular-nums">¥{(prevBalance + total).toLocaleString()}</span></div>
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

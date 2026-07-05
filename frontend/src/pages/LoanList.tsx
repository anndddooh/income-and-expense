import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
import { StateBadge, type State } from '@/components/StateIndicator'
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
import { pillPrimary, tableCard } from '@/lib/ui'
import { cn } from '@/lib/utils'
import { deleteLoan, fetchLoans, type Loan } from '@/api/loans'

export default function LoanList() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [deleting, setDeleting] = useState<Loan | null>(null)

  const { data: loans = [], isLoading, error } = useQuery({
    queryKey: ['loans'],
    queryFn: fetchLoans,
  })

  const delMut = useMutation({
    mutationFn: (id: number) => deleteLoan(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['loans'] })
      setDeleting(null)
      toast.success('削除しました')
    },
    onError: (e: unknown) => toast.error('削除失敗: ' + String(e)),
  })

  const isComplete = (l: { last_year: number; last_month: number }) =>
    year > l.last_year || (year === l.last_year && month > l.last_month)

  return (
    <>
      <PageHeader
        title="ローン"
        description={`${year}年${month}月 · ${loans.length}件`}
        actions={
          <button
            type="button"
            className={pillPrimary}
            onClick={() => navigate(`/loans/${year}/${month}/new`)}
          >
            ＋ ローンを追加
          </button>
        }
      />

      <div className={tableCard}>
        <Table>
          <TableHeader>
            <TableRow className="border-border hover:bg-transparent">
              {[
                '名称',
                '支払日',
                '開始',
                '終了',
                '支払方法',
                '口座',
              ].map((h) => (
                <TableHead
                  key={h}
                  className="text-[12px] font-bold text-muted-foreground"
                >
                  {h}
                </TableHead>
              ))}
              <TableHead className="text-right text-[12px] font-bold text-muted-foreground">
                初回
              </TableHead>
              <TableHead className="text-right text-[12px] font-bold text-muted-foreground">
                2回目以降
              </TableHead>
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                状態
              </TableHead>
              <TableHead className="text-[12px] font-bold text-muted-foreground">
                完了
              </TableHead>
              <TableHead className="w-14 text-right text-[12px] font-bold text-muted-foreground">
                操作
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading && (
              <TableRow>
                <TableCell colSpan={11} className="text-center text-muted-foreground">
                  読み込み中...
                </TableCell>
              </TableRow>
            )}
            {error && (
              <TableRow>
                <TableCell colSpan={11} className="text-center text-destructive">
                  エラー: {String(error)}
                </TableCell>
              </TableRow>
            )}
            {!isLoading && !error && loans.length === 0 && (
              <TableRow>
                <TableCell colSpan={11} className="text-center text-muted-foreground">
                  データがありません
                </TableCell>
              </TableRow>
            )}
            {loans.map((l) => {
              const complete = isComplete(l)
              return (
                <TableRow
                  key={l.id}
                  tabIndex={0}
                  className={cn(
                    'cursor-pointer border-row-separator text-[13.5px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                    complete && 'text-muted-foreground',
                  )}
                  onClick={() => navigate(`/loans/${year}/${month}/${l.id}/edit`)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      navigate(`/loans/${year}/${month}/${l.id}/edit`)
                    }
                  }}
                >
                  <TableCell className="font-bold">{l.name}</TableCell>
                  <TableCell className="tabular-nums">{l.pay_day}</TableCell>
                  <TableCell className="tabular-nums text-muted-foreground-2">
                    {l.first_year}/{l.first_month}
                  </TableCell>
                  <TableCell className="tabular-nums text-muted-foreground-2">
                    {l.last_year}/{l.last_month}
                  </TableCell>
                  <TableCell>{l.method_name}</TableCell>
                  <TableCell className="text-[13px] text-muted-foreground">
                    {l.account.user} / {l.account.bank}
                  </TableCell>
                  <TableCell className="text-right font-bold tabular-nums">
                    {l.formed_amount_first}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {l.formed_amount_from_second}
                  </TableCell>
                  <TableCell>
                    <StateBadge state={l.state as State} label={l.state_label} />
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {complete ? '完了' : '-'}
                  </TableCell>
                  <TableCell className="text-right">
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation()
                        setDeleting(l)
                      }}
                      aria-label="削除"
                      className="inline-flex size-7 items-center justify-center rounded-md transition-colors hover:bg-destructive/10"
                    >
                      <Trash2 className="size-[15px] text-destructive" />
                    </button>
                  </TableCell>
                </TableRow>
              )
            })}
          </TableBody>
        </Table>
      </div>

      <AlertDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>削除しますか?</AlertDialogTitle>
            <AlertDialogDescription>
              「{deleting?.name}」を削除します。
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

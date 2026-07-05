import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
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
import {
  deleteDefaultIncome,
  fetchDefaultIncomes,
  type DefaultIncome,
} from '@/api/default-incomes'

export default function DefaultIncomeList() {
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [deleting, setDeleting] = useState<DefaultIncome | null>(null)

  const { data: items = [], isLoading, error } = useQuery({
    queryKey: ['default-incomes'],
    queryFn: fetchDefaultIncomes,
  })

  const delMut = useMutation({
    mutationFn: (id: number) => deleteDefaultIncome(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['default-incomes'] })
      setDeleting(null)
      toast.success('削除しました')
    },
    onError: (e: unknown) => toast.error('削除失敗: ' + String(e)),
  })

  return (
    <>
      <PageHeader
        title="デフォルト収入"
        description="毎月自動で追加する収入のテンプレート"
        actions={
          <button
            type="button"
            className={pillPrimary}
            onClick={() => navigate('/settings/default-incomes/new')}
          >
            ＋ 新規作成
          </button>
        }
      />

      <div className={tableCard}>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>名称</TableHead>
                <TableHead>支払日</TableHead>
                <TableHead>支払方法</TableHead>
                <TableHead>口座</TableHead>
                <TableHead className="text-right">金額</TableHead>
                <TableHead>適用月</TableHead>
                <TableHead>状態</TableHead>
                <TableHead className="w-16 text-right">操作</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-muted-foreground">
                    読み込み中...
                  </TableCell>
                </TableRow>
              )}
              {error && (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-destructive">
                    エラー: {String(error)}
                  </TableCell>
                </TableRow>
              )}
              {!isLoading && !error && items.length === 0 && (
                <TableRow>
                  <TableCell colSpan={8} className="text-center text-muted-foreground">
                    データがありません
                  </TableCell>
                </TableRow>
              )}
              {items.map((it) => (
                <TableRow
                  key={it.id}
                  tabIndex={0}
                  className="cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  onClick={() =>
                    navigate(`/settings/default-incomes/${it.id}/edit`)
                  }
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      navigate(`/settings/default-incomes/${it.id}/edit`)
                    }
                  }}
                >
                  <TableCell className="font-bold">{it.name}</TableCell>
                  <TableCell>{it.pay_day}</TableCell>
                  <TableCell>{it.method_name}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {it.account.user} / {it.account.bank}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {it.formed_amount}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {it.months.length === 0
                      ? '-'
                      : it.months.map((m) => `${m}月`).join(', ')}
                  </TableCell>
                  <TableCell>
                    <StateBadge
                      state={it.state as State}
                      label={it.state_label}
                    />
                  </TableCell>
                  <TableCell className="text-right">
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation()
                        setDeleting(it)
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

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Plus, Trash2 } from 'lucide-react'
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
import { Badge } from '@/components/ui/badge'
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
        title="ローン一覧"
        description={`${year}年${month}月`}
        actions={
          <Button
            size="sm"
            onClick={() => navigate(`/loans/${year}/${month}/new`)}
          >
            <Plus className="size-4" />
            新規作成
          </Button>
        }
      />

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>名称</TableHead>
                <TableHead>支払日</TableHead>
                <TableHead>開始</TableHead>
                <TableHead>終了</TableHead>
                <TableHead>支払方法</TableHead>
                <TableHead>口座</TableHead>
                <TableHead className="text-right">初回</TableHead>
                <TableHead className="text-right">2回目以降</TableHead>
                <TableHead>状態</TableHead>
                <TableHead>完了</TableHead>
                <TableHead className="w-16 text-right">操作</TableHead>
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
                      'cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                      complete && 'text-muted-foreground'
                    )}
                    onClick={() =>
                      navigate(`/loans/${year}/${month}/${l.id}/edit`)
                    }
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        navigate(`/loans/${year}/${month}/${l.id}/edit`)
                      }
                    }}
                  >
                    <TableCell
                      className={`font-medium ${stateBarClass(l.state as State)}`}
                    >
                      {l.name}
                    </TableCell>
                    <TableCell>{l.pay_day}</TableCell>
                    <TableCell>
                      {l.first_year}/{l.first_month}
                    </TableCell>
                    <TableCell>
                      {l.last_year}/{l.last_month}
                    </TableCell>
                    <TableCell>{l.method_name}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {l.account.user} / {l.account.bank}
                    </TableCell>
                    <TableCell className="text-right tabular-nums">
                      {l.formed_amount_first}
                    </TableCell>
                    <TableCell className="text-right tabular-nums">
                      {l.formed_amount_from_second}
                    </TableCell>
                    <TableCell>
                      <StateBadge
                        state={l.state as State}
                        label={l.state_label}
                      />
                    </TableCell>
                    <TableCell>
                      {complete ? <Badge variant="secondary">完了</Badge> : '-'}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        size="icon"
                        variant="ghost"
                        onClick={(e) => {
                          e.stopPropagation()
                          setDeleting(l)
                        }}
                        aria-label="削除"
                      >
                        <Trash2 className="size-4 text-destructive" />
                      </Button>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

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

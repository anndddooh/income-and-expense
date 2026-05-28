import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
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
import {
  fetchMethodRequire,
  methodDone,
  type MethodRequireRow,
} from '@/api/requires'

export default function MethodRequire() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
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

  return (
    <>
      <PageHeader title="支払方法別必要金額" description={`${year}年${month}月`} />

      {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
      {error && <p className="text-destructive">エラー: {String(error)}</p>}

      {data && (
        <>
          <Card className="mb-6">
            <CardHeader className="pb-2">
              <CardDescription>必要額合計</CardDescription>
              <CardTitle className="text-2xl tabular-nums">
                ¥{data.require_sum.toLocaleString()}
              </CardTitle>
            </CardHeader>
            <CardContent />
          </Card>

          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>支払方法</TableHead>
                    <TableHead className="text-right">必要額</TableHead>
                    <TableHead className="w-32 text-right">操作</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {data.methods.map((m) => (
                    <TableRow key={m.id}>
                      <TableCell>{m.display_name}</TableCell>
                      <TableCell className="text-right tabular-nums">
                        {m.formed_require}
                      </TableCell>
                      <TableCell className="text-right">
                        {m.require > 0 && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => setTarget(m)}
                          >
                            一括完了
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </>
      )}

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

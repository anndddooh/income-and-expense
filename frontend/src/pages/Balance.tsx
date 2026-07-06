import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
import SummaryCard from '@/components/SummaryCard'
import { Input } from '@/components/ui/input'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { pillCancel, pillOutlineSm, pillPrimary, tableCard } from '@/lib/ui'
import {
  fetchBalance,
  updateAccountBalance,
  type AccountRow,
} from '@/api/balance'

export default function Balance() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
  const qc = useQueryClient()

  const key = ['balance', year, month]
  const { data, isLoading, error } = useQuery({
    queryKey: key,
    queryFn: () => fetchBalance(year, month),
  })

  const [editing, setEditing] = useState<number | null>(null)
  const [draft, setDraft] = useState('')

  const mut = useMutation({
    mutationFn: ({ id, balance }: { id: number; balance: number }) =>
      updateAccountBalance(id, balance),
    onSuccess: () => {
      setEditing(null)
      qc.invalidateQueries({ queryKey: key })
      toast.success('残高を更新しました')
    },
    onError: (e: unknown) => toast.error('更新失敗: ' + String(e)),
  })

  const startEdit = (row: AccountRow) => {
    setEditing(row.id)
    setDraft(String(row.balance))
  }

  return (
    <>
      <PageHeader title="残高" description={`${year}年${month}月`} />

      {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
      {error && <p className="text-destructive">エラー: {String(error)}</p>}

      {data && (
        <>
          <div className="mb-4 grid gap-4 md:grid-cols-3">
            <SummaryCard
              label="実残高合計"
              value={`¥${data.balance_sum.toLocaleString()}`}
            />
            <SummaryCard
              label="DB残高(完了分)"
              value={`¥${data.balance_on_db.toLocaleString()}`}
            />
            <SummaryCard
              label="差額"
              value={`¥${data.balance_diff.toLocaleString()}`}
              valueClassName={
                data.balance_diff === 0 ? 'text-income' : 'text-expense'
              }
            />
          </div>

          <div className={tableCard}>
            <Table>
              <TableHeader>
                <TableRow className="border-border hover:bg-transparent">
                  <TableHead className="text-[12px] font-bold text-muted-foreground">
                    ユーザー
                  </TableHead>
                  <TableHead className="text-[12px] font-bold text-muted-foreground">
                    銀行
                  </TableHead>
                  <TableHead className="text-right text-[12px] font-bold text-muted-foreground">
                    実残高
                  </TableHead>
                  <TableHead className="w-44 text-right text-[12px] font-bold text-muted-foreground">
                    操作
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.accounts.map((a) => (
                  <TableRow
                    key={a.id}
                    className="border-row-separator text-[13.5px] hover:bg-transparent"
                  >
                    <TableCell>{a.user}</TableCell>
                    <TableCell className="font-bold">{a.bank}</TableCell>
                    <TableCell className="text-right tabular-nums">
                      {editing === a.id ? (
                        <Input
                          type="number"
                          value={draft}
                          onChange={(e) => setDraft(e.target.value)}
                          className="ml-auto w-36"
                        />
                      ) : (
                        a.formed_balance
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      {editing === a.id ? (
                        <div className="flex justify-end gap-2">
                          <button
                            type="button"
                            className={pillPrimary}
                            onClick={() =>
                              mut.mutate({ id: a.id, balance: Number(draft) })
                            }
                            disabled={mut.isPending}
                          >
                            保存
                          </button>
                          <button
                            type="button"
                            className={pillCancel}
                            onClick={() => setEditing(null)}
                          >
                            キャンセル
                          </button>
                        </div>
                      ) : (
                        <button
                          type="button"
                          className={pillOutlineSm}
                          onClick={() => startEdit(a)}
                        >
                          編集
                        </button>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </>
      )}
    </>
  )
}

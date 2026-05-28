import { useQuery } from '@tanstack/react-query'
import { useParams } from 'react-router-dom'
import PageHeader from '@/components/PageHeader'
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
import { fetchAccountRequire } from '@/api/requires'

export default function AccountRequire() {
  const { year: y, month: m } = useParams<{ year: string; month: string }>()
  const year = Number(y)
  const month = Number(m)
  const { data, isLoading, error } = useQuery({
    queryKey: ['account-require', year, month],
    queryFn: () => fetchAccountRequire(year, month),
  })

  return (
    <>
      <PageHeader
        title="口座別必要金額"
        description={`${year}年${month}月`}
      />

      {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
      {error && <p className="text-destructive">エラー: {String(error)}</p>}

      {data && (
        <>
          <div className="mb-6 grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader className="pb-2">
                <CardDescription>必要額合計</CardDescription>
                <CardTitle className="text-2xl tabular-nums">
                  ¥{data.require_sum.toLocaleString()}
                </CardTitle>
              </CardHeader>
              <CardContent />
            </Card>
            <Card>
              <CardHeader className="pb-2">
                <CardDescription>不足額合計</CardDescription>
                <CardTitle
                  className={cn(
                    'text-2xl tabular-nums',
                    data.insufficient_sum > 0
                      ? 'text-destructive'
                      : 'text-green-600'
                  )}
                >
                  ¥{data.insufficient_sum.toLocaleString()}
                </CardTitle>
              </CardHeader>
              <CardContent />
            </Card>
          </div>

          <Card>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>ユーザー</TableHead>
                    <TableHead>銀行</TableHead>
                    <TableHead className="text-right">残高</TableHead>
                    <TableHead className="text-right">必要額</TableHead>
                    <TableHead className="text-right">不足額</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {data.accounts.map((a) => (
                    <TableRow
                      key={a.id}
                      className={cn(a.is_insufficient && 'bg-destructive/10')}
                    >
                      <TableCell>{a.user}</TableCell>
                      <TableCell>{a.bank}</TableCell>
                      <TableCell className="text-right tabular-nums">
                        {a.formed_balance}
                      </TableCell>
                      <TableCell className="text-right tabular-nums">
                        {a.formed_require}
                      </TableCell>
                      <TableCell className="text-right tabular-nums">
                        {a.is_insufficient ? (
                          <span className="font-semibold text-destructive">
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
            </CardContent>
          </Card>
        </>
      )}
    </>
  )
}

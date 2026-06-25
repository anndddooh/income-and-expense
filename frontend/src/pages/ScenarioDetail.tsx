import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Plus, Trash2 } from 'lucide-react'
import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip as ChartTooltip,
} from 'recharts'
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
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { cn } from '@/lib/utils'
import {
  createScenarioItem,
  deleteScenarioItem,
  fetchHistoryAverage,
  fetchScenario,
  fetchScenarioSummary,
  patchScenarioItem,
  updateScenarioItem,
  type ScenarioItem,
} from '@/api/scenarios'
import { EXPENSE_CATEGORY_LABELS, type ExpenseCategoryValue } from '@/api/default-expenses'

type ItemDraft = {
  id?: number
  name: string
  pay_day: number
  amount: number
  category: ExpenseCategoryValue
  is_required: boolean
  is_enabled: boolean
  months: number[]
}

const EMPTY_DRAFT: ItemDraft = {
  name: '',
  pay_day: 1,
  amount: 0,
  category: 1,
  is_required: true,
  is_enabled: true,
  months: Array.from({ length: 12 }, (_, i) => i + 1),
}

const MONTH_OPTIONS = Array.from({ length: 12 }, (_, i) => i + 1)
const CURRENT_MONTH = new Date().getMonth() + 1

const CATEGORY_COLOR: Record<ExpenseCategoryValue, string> = {
  1: '#3b82f6',
  2: '#f59e0b',
  3: '#a855f7',
}

export default function ScenarioDetail() {
  const { id } = useParams<{ id: string }>()
  const scenarioId = Number(id)
  const navigate = useNavigate()
  const qc = useQueryClient()

  const [mode, setMode] = useState<'monthly' | 'yearly'>('monthly')
  const [targetMonth, setTargetMonth] = useState<number>(CURRENT_MONTH)
  const [editing, setEditing] = useState<ItemDraft | null>(null)
  const [deleting, setDeleting] = useState<ScenarioItem | null>(null)

  const { data: scenario } = useQuery({
    queryKey: ['scenario', scenarioId],
    queryFn: () => fetchScenario(scenarioId),
    enabled: !!scenarioId,
  })

  const summaryQuery = useQuery({
    queryKey: ['scenario-summary', scenarioId, mode, mode === 'monthly' ? targetMonth : null],
    queryFn: () => fetchScenarioSummary(
      scenarioId, mode, mode === 'monthly' ? targetMonth : undefined,
    ),
    enabled: !!scenarioId,
  })

  const invalidateAll = () => {
    qc.invalidateQueries({ queryKey: ['scenario', scenarioId] })
    qc.invalidateQueries({ queryKey: ['scenario-summary', scenarioId] })
  }

  const saveMut = useMutation({
    mutationFn: async (draft: ItemDraft) => {
      const payload = {
        scenario: scenarioId,
        name: draft.name.trim(),
        pay_day: draft.pay_day,
        amount: draft.amount,
        category: draft.category,
        is_required: draft.is_required,
        is_enabled: draft.is_enabled,
        months: draft.months,
      }
      return draft.id
        ? updateScenarioItem(draft.id, payload)
        : createScenarioItem(payload)
    },
    onSuccess: () => {
      invalidateAll()
      setEditing(null)
      toast.success('保存しました')
    },
    onError: (e: unknown) => toast.error('保存失敗: ' + String(e)),
  })

  const delMut = useMutation({
    mutationFn: (id: number) => deleteScenarioItem(id),
    onSuccess: () => {
      invalidateAll()
      setDeleting(null)
      toast.success('削除しました')
    },
    onError: (e: unknown) => toast.error('削除失敗: ' + String(e)),
  })

  const toggleMut = useMutation({
    mutationFn: ({ id, is_enabled }: { id: number; is_enabled: boolean }) =>
      patchScenarioItem(id, { is_enabled }),
    onSuccess: () => invalidateAll(),
  })

  const optionalOffMut = useMutation({
    mutationFn: async () => {
      if (!scenario) return
      await Promise.all(
        scenario.items
          .filter((it) => !it.is_required && it.is_enabled)
          .map((it) => patchScenarioItem(it.id, { is_enabled: false })),
      )
    },
    onSuccess: () => {
      invalidateAll()
      toast.success('任意支出を全てオフにしました')
    },
  })

  const items = scenario?.items ?? []
  const summary = summaryQuery.data

  const optionalOnSum = useMemo(() => {
    return items
      .filter((it) => !it.is_required && it.is_enabled)
      .reduce((s, it) => s + it.amount, 0)
  }, [items])

  if (!scenario) {
    return <div className="text-muted-foreground">読み込み中...</div>
  }

  return (
    <>
      <PageHeader
        title={scenario.name}
        description={scenario.note || 'シナリオの妥当性を月次/年次で評価できます'}
        actions={
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => navigate('/scenarios')}>
              一覧に戻る
            </Button>
            <Button size="sm" onClick={() => setEditing({ ...EMPTY_DRAFT })}>
              <Plus className="size-4" />
              項目追加
            </Button>
          </div>
        }
      />

      <div className="grid gap-6 lg:grid-cols-[1fr_360px]">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle>項目一覧</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-16">有効</TableHead>
                  <TableHead>名称</TableHead>
                  <TableHead>区分</TableHead>
                  <TableHead>必須</TableHead>
                  <TableHead className="text-right">金額</TableHead>
                  <TableHead>適用月</TableHead>
                  <TableHead className="w-16 text-right">操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center text-muted-foreground">
                      項目がありません
                    </TableCell>
                  </TableRow>
                )}
                {items.map((it) => (
                  <TableRow
                    key={it.id}
                    className={cn(
                      'cursor-pointer',
                      !it.is_enabled && 'opacity-50',
                    )}
                    onClick={() => setEditing({
                      id: it.id,
                      name: it.name,
                      pay_day: it.pay_day,
                      amount: it.amount,
                      category: it.category,
                      is_required: it.is_required,
                      is_enabled: it.is_enabled,
                      months: it.months,
                    })}
                  >
                    <TableCell onClick={(e) => e.stopPropagation()}>
                      <input
                        type="checkbox"
                        checked={it.is_enabled}
                        onChange={(e) => toggleMut.mutate({
                          id: it.id, is_enabled: e.target.checked,
                        })}
                      />
                    </TableCell>
                    <TableCell className="font-medium">{it.name}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{it.category_label}</Badge>
                    </TableCell>
                    <TableCell>
                      <Badge variant={it.is_required ? 'default' : 'secondary'}>
                        {it.is_required ? '必須' : '任意'}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right tabular-nums">
                      ¥{it.amount.toLocaleString()}
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {it.months.length === 12
                        ? '毎月'
                        : it.months.map((m) => `${m}`).join(',') + '月'}
                    </TableCell>
                    <TableCell
                      className="text-right"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <Button
                        size="icon"
                        variant="ghost"
                        onClick={() => setDeleting(it)}
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

        <div className="space-y-4">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base">集計</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant={mode === 'monthly' ? 'default' : 'outline'}
                  onClick={() => setMode('monthly')}
                >
                  月次
                </Button>
                <Button
                  size="sm"
                  variant={mode === 'yearly' ? 'default' : 'outline'}
                  onClick={() => setMode('yearly')}
                >
                  年次
                </Button>
                {mode === 'monthly' && (
                  <Select
                    value={String(targetMonth)}
                    onValueChange={(v) => setTargetMonth(Number(v))}
                  >
                    <SelectTrigger className="ml-auto w-[100px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {MONTH_OPTIONS.map((m) => (
                        <SelectItem key={m} value={String(m)}>
                          {m}月
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              </div>

              {summary && (
                <div className="space-y-1 text-sm">
                  <SummaryRow label="収入" value={summary.income} bold />
                  <SummaryRow label="固定費" value={summary.fixed} />
                  <SummaryRow label="変動費" value={summary.variable} />
                  <SummaryRow label="単発" value={summary.one_time} />
                  <SummaryRow label="合計支出" value={summary.total_expense} bold />
                  <div className="border-t my-2" />
                  <SummaryRow
                    label="収支"
                    value={summary.balance}
                    bold
                    tone={summary.balance < 0 ? 'destructive' : 'positive'}
                  />
                  <div className="border-t my-2" />
                  <SummaryRow label="必須支出計" value={summary.required} />
                  <SummaryRow label="任意支出計" value={summary.optional} />
                </div>
              )}

              {optionalOnSum > 0 && (
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full"
                  onClick={() => optionalOffMut.mutate()}
                  disabled={optionalOffMut.isPending}
                >
                  任意支出を全てオフ (¥{optionalOnSum.toLocaleString()} 浮きます)
                </Button>
              )}
            </CardContent>
          </Card>

          {summary && (summary.fixed + summary.variable + summary.one_time) > 0 && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">区分比率</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-48">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={[
                          { name: '固定費', value: summary.fixed, fill: CATEGORY_COLOR[1] },
                          { name: '変動費', value: summary.variable, fill: CATEGORY_COLOR[2] },
                          { name: '単発', value: summary.one_time, fill: CATEGORY_COLOR[3] },
                        ].filter((d) => d.value > 0)}
                        dataKey="value"
                        outerRadius={70}
                        label={(d: { name?: string }) => d.name ?? ''}
                      >
                        {[CATEGORY_COLOR[1], CATEGORY_COLOR[2], CATEGORY_COLOR[3]].map((c, i) => (
                          <Cell key={i} fill={c} />
                        ))}
                      </Pie>
                      <ChartTooltip
                        formatter={(v) => `¥${Number(v).toLocaleString()}`}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {editing && (
        <ItemEditDialog
          draft={editing}
          onClose={() => setEditing(null)}
          onSave={(d) => saveMut.mutate(d)}
          isSaving={saveMut.isPending}
        />
      )}

      <AlertDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>削除しますか?</AlertDialogTitle>
            <AlertDialogDescription>
              「{deleting?.name}」をこのシナリオから削除します。
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

function SummaryRow({
  label,
  value,
  bold,
  tone,
}: {
  label: string
  value: number
  bold?: boolean
  tone?: 'destructive' | 'positive'
}) {
  return (
    <div className="flex justify-between">
      <span className={cn('text-muted-foreground', bold && 'text-foreground')}>
        {label}
      </span>
      <span
        className={cn(
          'tabular-nums',
          bold && 'font-semibold',
          tone === 'destructive' && 'text-destructive',
          tone === 'positive' && value > 0 && 'text-emerald-600 dark:text-emerald-400',
        )}
      >
        ¥{value.toLocaleString()}
      </span>
    </div>
  )
}

function ItemEditDialog({
  draft,
  onClose,
  onSave,
  isSaving,
}: {
  draft: ItemDraft
  onClose: () => void
  onSave: (d: ItemDraft) => void
  isSaving: boolean
}) {
  const [local, setLocal] = useState<ItemDraft>(draft)

  const avgQuery = useQuery({
    queryKey: ['history-average', local.name, 3],
    queryFn: () => fetchHistoryAverage(local.name.trim(), 3),
    enabled: local.category === 2 && local.name.trim().length > 0,
  })

  const showAvg = local.category === 2 && avgQuery.data && avgQuery.data.count > 0

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{draft.id ? '項目を編集' : '項目を追加'}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label>名称</Label>
            <Input
              value={local.name}
              onChange={(e) => setLocal({ ...local, name: e.target.value })}
            />
          </div>
          <div className="space-y-2">
            <Label>区分</Label>
            <Select
              value={String(local.category)}
              onValueChange={(v) => setLocal({
                ...local,
                category: Number(v) as ExpenseCategoryValue,
              })}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {(Object.keys(EXPENSE_CATEGORY_LABELS) as unknown as ExpenseCategoryValue[])
                  .map((v) => (
                    <SelectItem key={v} value={String(v)}>
                      {EXPENSE_CATEGORY_LABELS[v]}
                    </SelectItem>
                  ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>金額</Label>
            <Input
              type="number"
              value={local.amount === 0 ? '' : local.amount}
              onChange={(e) => setLocal({
                ...local,
                amount: e.target.value === '' ? 0 : Number(e.target.value),
              })}
            />
            {showAvg && (
              <p className="text-xs text-muted-foreground">
                過去3ヶ月の実績平均: ¥{avgQuery.data!.average.toLocaleString()}
                （{avgQuery.data!.count}件）
              </p>
            )}
          </div>
          <div className="space-y-2">
            <Label>支払日 (1-28)</Label>
            <Input
              type="number"
              min={1}
              max={28}
              value={local.pay_day}
              onChange={(e) => setLocal({
                ...local,
                pay_day: Math.max(1, Math.min(28, Number(e.target.value) || 1)),
              })}
            />
          </div>
          <div className="space-y-2">
            <Label>必須／任意</Label>
            <Select
              value={local.is_required ? 'required' : 'optional'}
              onValueChange={(v) => setLocal({ ...local, is_required: v === 'required' })}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="required">必須</SelectItem>
                <SelectItem value="optional">任意</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>適用月</Label>
            <div className="flex flex-wrap gap-2">
              {MONTH_OPTIONS.map((m) => {
                const active = local.months.includes(m)
                return (
                  <button
                    key={m}
                    type="button"
                    onClick={() => {
                      const next = active
                        ? local.months.filter((x) => x !== m)
                        : [...local.months, m].sort((a, b) => a - b)
                      setLocal({ ...local, months: next })
                    }}
                    className={cn(
                      'h-8 w-10 rounded-md border text-sm',
                      active
                        ? 'border-primary bg-primary text-primary-foreground'
                        : 'border-input bg-background',
                    )}
                  >
                    {m}
                  </button>
                )
              })}
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>キャンセル</Button>
          <Button
            disabled={!local.name.trim() || isSaving}
            onClick={() => onSave(local)}
          >
            保存
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

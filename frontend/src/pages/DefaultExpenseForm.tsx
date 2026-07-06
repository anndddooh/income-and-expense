import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate, useParams } from 'react-router-dom'
import { z } from 'zod'
import PageHeader from '@/components/PageHeader'
import { Segmented } from '@/components/Segmented'
import { STATE_META } from '@/components/StateIndicator'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { card, fieldLabel, pillCancel, pillOutlineSm, pillPrimary } from '@/lib/ui'
import { cn } from '@/lib/utils'
import { applyServerErrors } from '@/lib/form-errors'
import {
  createDefaultExpense,
  fetchDefaultExpense,
  updateDefaultExpense,
  type ExpenseCategoryValue,
} from '@/api/default-expenses'
import { fetchMethods } from '@/api/methods'

const schema = z.object({
  name: z.string().min(1, '名称は必須です'),
  pay_day: z
    .number()
    .int()
    .min(1, '1〜28の範囲で指定してください')
    .max(28, '1〜28の範囲で指定してください'),
  method: z.number().int().positive('支払方法を選択してください'),
  amount: z.number().int().min(0, '金額は0以上で入力してください'),
  state: z.number().int().min(0).max(2),
  months: z.array(z.number().int().min(1).max(12)),
  category: z.number().int().min(1).max(3),
  is_required: z.boolean(),
})

type FormValues = z.infer<typeof schema>

const STATE_OPTS = [
  { value: '0', label: '未定', activeColor: STATE_META[0].color },
  { value: '1', label: '確定', activeColor: STATE_META[1].color },
  { value: '2', label: '完了', activeColor: STATE_META[2].color },
]

const selectCls = 'h-[42px] rounded-input bg-white'

const CATEGORIES = [
  { value: '1', label: '固定費' },
  { value: '2', label: '変動費' },
  { value: '3', label: '単発' },
]

const MONTH_OPTIONS = Array.from({ length: 12 }, (_, i) => i + 1)

const FIELDS = [
  'name', 'pay_day', 'method', 'amount', 'state', 'months',
  'category', 'is_required',
] as const

export default function DefaultExpenseForm() {
  const { id } = useParams<{ id?: string }>()
  const isEdit = !!id
  const itemId = id ? Number(id) : undefined
  const navigate = useNavigate()
  const qc = useQueryClient()

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      pay_day: 1,
      method: 0,
      amount: 0,
      state: 0,
      months: [],
      category: 1,
      is_required: true,
    },
  })

  const { data: methods = [] } = useQuery({
    queryKey: ['methods'],
    queryFn: fetchMethods,
  })
  const { data: existing } = useQuery({
    queryKey: ['default-expense', itemId],
    queryFn: () => fetchDefaultExpense(itemId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (existing && methods.length > 0) {
      form.reset({
        name: existing.name,
        pay_day: existing.pay_day,
        method: existing.method,
        amount: existing.amount,
        state: existing.state,
        months: existing.months,
        category: existing.category,
        is_required: existing.is_required,
      })
    }
  }, [existing, methods.length, form])

  useEffect(() => {
    if (!isEdit && form.getValues('method') === 0 && methods[0]) {
      form.setValue('method', methods[0].id)
    }
  }, [methods, isEdit, form])

  const mut = useMutation({
    mutationFn: (values: FormValues) => {
      const payload = {
        ...values,
        state: values.state as 0 | 1 | 2,
        category: values.category as ExpenseCategoryValue,
      }
      return isEdit
        ? updateDefaultExpense(itemId!, payload)
        : createDefaultExpense(payload)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['default-expenses'] })
      navigate('/settings/default-expenses')
    },
    onError: (e: unknown) => {
      const rootMsg = applyServerErrors(e, form.setError, FIELDS)
      if (rootMsg) form.setError('root', { type: 'server', message: rootMsg })
    },
  })

  return (
    <div className="max-w-xl">
      <PageHeader title={isEdit ? 'デフォルト支出を編集' : 'デフォルト支出を追加'} />
      <div className={`${card} p-[26px]`}>
          <Form {...form}>
            <form
              className="space-y-4"
              onSubmit={form.handleSubmit((v) => {
                form.clearErrors('root')
                mut.mutate(v)
              })}
            >
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>名称</FormLabel>
                    <FormControl>
                      <Input {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="pay_day"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>支払日 (1-28)</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={1}
                        max={28}
                        {...field}
                        value={field.value === 0 ? '' : field.value}
                        onChange={(e) =>
                          field.onChange(
                            e.target.value === '' ? 0 : Number(e.target.value)
                          )
                        }
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="method"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>支払方法</FormLabel>
                    <Select
                      value={field.value ? String(field.value) : undefined}
                      onValueChange={(v) => field.onChange(Number(v))}
                    >
                      <FormControl>
                        <SelectTrigger className={selectCls}>
                          <SelectValue placeholder="選択" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {methods.map((m) => (
                          <SelectItem key={m.id} value={String(m.id)}>
                            {m.display_name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="amount"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>金額</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={0}
                        {...field}
                        value={field.value === 0 ? '' : field.value}
                        onChange={(e) =>
                          field.onChange(
                            e.target.value === '' ? 0 : Number(e.target.value)
                          )
                        }
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="state"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className={fieldLabel}>状態</FormLabel>
                    <FormControl>
                      <Segmented
                        value={String(field.value)}
                        onChange={(v) => field.onChange(Number(v))}
                        options={STATE_OPTS}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="category"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>費目区分</FormLabel>
                    <Select
                      value={String(field.value)}
                      onValueChange={(v) => field.onChange(Number(v))}
                    >
                      <FormControl>
                        <SelectTrigger className={selectCls}>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {CATEGORIES.map((c) => (
                          <SelectItem key={c.value} value={c.value}>
                            {c.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="is_required"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>必須／任意</FormLabel>
                    <Select
                      value={field.value ? 'required' : 'optional'}
                      onValueChange={(v) => field.onChange(v === 'required')}
                    >
                      <FormControl>
                        <SelectTrigger className={selectCls}>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="required">必須</SelectItem>
                        <SelectItem value="optional">任意</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="months"
                render={({ field }) => {
                  const selected = new Set(field.value)
                  const toggle = (m: number) => {
                    const next = new Set(selected)
                    if (next.has(m)) next.delete(m)
                    else next.add(m)
                    field.onChange(Array.from(next).sort((a, b) => a - b))
                  }
                  const setAll = () => field.onChange([...MONTH_OPTIONS])
                  const clearAll = () => field.onChange([])
                  return (
                    <FormItem>
                      <FormLabel>適用月</FormLabel>
                      <div className="flex flex-wrap gap-2">
                        {MONTH_OPTIONS.map((m) => {
                          const active = selected.has(m)
                          return (
                            <button
                              key={m}
                              type="button"
                              onClick={() => toggle(m)}
                              className={cn(
                                'h-8 w-12 rounded-full border text-[13px] font-bold transition-colors',
                                active
                                  ? 'border-primary bg-primary text-primary-foreground'
                                  : 'border-input bg-white text-muted-foreground-2 hover:bg-primary-soft/40'
                              )}
                            >
                              {m}月
                            </button>
                          )
                        })}
                      </div>
                      <div className="mt-2 flex gap-2">
                        <button type="button" className={pillOutlineSm} onClick={setAll}>
                          全選択
                        </button>
                        <button type="button" className={pillOutlineSm} onClick={clearAll}>
                          クリア
                        </button>
                      </div>
                      <FormMessage />
                    </FormItem>
                  )
                }}
              />

              {form.formState.errors.root && (
                <p className="text-sm text-destructive">
                  {form.formState.errors.root.message}
                </p>
              )}

              <div className="flex gap-2.5 pt-1">
                <button type="submit" className={pillPrimary} disabled={mut.isPending}>
                  {isEdit ? '更新する' : '追加する'}
                </button>
                <button
                  type="button"
                  className={pillCancel}
                  onClick={() => navigate('/settings/default-expenses')}
                >
                  キャンセル
                </button>
              </div>
            </form>
          </Form>
      </div>
    </div>
  )
}

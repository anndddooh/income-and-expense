import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate, useParams } from 'react-router-dom'
import { z } from 'zod'
import PageHeader from '@/components/PageHeader'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
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
import { cn } from '@/lib/utils'
import { applyServerErrors } from '@/lib/form-errors'
import {
  createDefaultIncome,
  fetchDefaultIncome,
  updateDefaultIncome,
} from '@/api/default-incomes'
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
})

type FormValues = z.infer<typeof schema>

const STATES = [
  { value: '0', label: '未定' },
  { value: '1', label: '確定' },
  { value: '2', label: '完了' },
]

const MONTH_OPTIONS = Array.from({ length: 12 }, (_, i) => i + 1)

const FIELDS = ['name', 'pay_day', 'method', 'amount', 'state', 'months'] as const

export default function DefaultIncomeForm() {
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
    },
  })

  const { data: methods = [] } = useQuery({
    queryKey: ['methods'],
    queryFn: fetchMethods,
  })
  const { data: existing } = useQuery({
    queryKey: ['default-income', itemId],
    queryFn: () => fetchDefaultIncome(itemId!),
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
      const payload = { ...values, state: values.state as 0 | 1 | 2 }
      return isEdit
        ? updateDefaultIncome(itemId!, payload)
        : createDefaultIncome(payload)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['default-incomes'] })
      navigate('/settings/default-incomes')
    },
    onError: (e: unknown) => {
      const rootMsg = applyServerErrors(e, form.setError, FIELDS)
      if (rootMsg) form.setError('root', { type: 'server', message: rootMsg })
    },
  })

  return (
    <div className="max-w-xl">
      <PageHeader title={isEdit ? 'デフォルト収入を編集' : 'デフォルト収入を追加'} />
      <Card>
        <CardContent className="pt-6">
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
                        onChange={(e) => field.onChange(Number(e.target.value))}
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
                        <SelectTrigger>
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
                    <FormLabel>状態</FormLabel>
                    <Select
                      value={String(field.value)}
                      onValueChange={(v) => field.onChange(Number(v))}
                    >
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {STATES.map((s) => (
                          <SelectItem key={s.value} value={s.value}>
                            {s.label}
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
                                'h-8 w-12 rounded-md border text-sm transition-colors',
                                active
                                  ? 'border-primary bg-primary text-primary-foreground'
                                  : 'border-input bg-background hover:bg-accent'
                              )}
                            >
                              {m}月
                            </button>
                          )
                        })}
                      </div>
                      <div className="mt-2 flex gap-2">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={setAll}
                        >
                          全選択
                        </Button>
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          onClick={clearAll}
                        >
                          クリア
                        </Button>
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

              <div className="flex gap-2 pt-2">
                <Button type="submit" disabled={mut.isPending}>
                  {isEdit ? '更新' : '追加'}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate('/settings/default-incomes')}
                >
                  キャンセル
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  )
}

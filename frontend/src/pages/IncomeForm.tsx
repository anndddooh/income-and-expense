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
import { Textarea } from '@/components/ui/textarea'
import { card, fieldLabel, pillCancel, pillPrimary } from '@/lib/ui'
import { applyServerErrors } from '@/lib/form-errors'
import { createIncome, fetchIncome, updateIncome } from '@/api/incomes'
import { fetchMethods } from '@/api/methods'

const schema = z.object({
  name: z.string().min(1, '名称は必須です'),
  pay_date: z.string().min(1, '支払日は必須です'),
  method: z.number().int().positive('支払方法を選択してください'),
  amount: z.number().int().min(0, '金額は0以上で入力してください'),
  state: z.number().int().min(0).max(2),
  memo: z.string().nullable().optional(),
})

type FormValues = z.infer<typeof schema>

const STATE_OPTS = [
  { value: '0', label: '未定', activeColor: STATE_META[0].color },
  { value: '1', label: '確定', activeColor: STATE_META[1].color },
  { value: '2', label: '完了', activeColor: STATE_META[2].color },
]

const inputCls = 'h-[42px] rounded-input bg-white'

const FIELDS = ['name', 'pay_date', 'method', 'amount', 'state', 'memo'] as const

export default function IncomeForm() {
  const { year: y, month: m, id } = useParams<{
    year: string
    month: string
    id?: string
  }>()
  const year = Number(y)
  const month = Number(m)
  const isEdit = !!id
  const incomeId = id ? Number(id) : undefined
  const navigate = useNavigate()
  const qc = useQueryClient()

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      pay_date: (() => {
        const now = new Date()
        const day = now.getFullYear() === year && now.getMonth() + 1 === month
          ? now.getDate() : 1
        return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
      })(),
      method: 0,
      amount: 0,
      state: 0,
      memo: '',
    },
  })

  const { data: methods = [] } = useQuery({
    queryKey: ['methods'],
    queryFn: fetchMethods,
  })
  const { data: existing } = useQuery({
    queryKey: ['income', incomeId],
    queryFn: () => fetchIncome(incomeId!),
    enabled: isEdit,
  })

  useEffect(() => {
    if (existing && methods.length > 0) {
      form.reset({
        name: existing.name,
        pay_date: existing.pay_date,
        method: existing.method,
        amount: existing.amount,
        state: existing.state,
        memo: existing.memo ?? '',
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
      return isEdit ? updateIncome(incomeId!, payload) : createIncome(payload)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['incomes', year, month] })
      navigate(`/incomes/${year}/${month}`)
    },
    onError: (e: unknown) => {
      const rootMsg = applyServerErrors(e, form.setError, FIELDS)
      if (rootMsg) form.setError('root', { type: 'server', message: rootMsg })
    },
  })

  return (
    <div className="max-w-2xl">
      <PageHeader
        title={isEdit ? '収入を編集' : '収入を追加'}
        description={`${year}年${month}月`}
      />
      <div className={`${card} p-[26px]`}>
        <Form {...form}>
          <form
            className="grid gap-4"
            onSubmit={form.handleSubmit((v) => {
              form.clearErrors('root')
              mut.mutate(v)
            })}
          >
            <div className="grid gap-4 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className={fieldLabel}>名称</FormLabel>
                    <FormControl>
                      <Input className={inputCls} {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="pay_date"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className={fieldLabel}>支払日</FormLabel>
                    <FormControl>
                      <Input type="date" className={inputCls} {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="method"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className={fieldLabel}>支払方法</FormLabel>
                    <Select
                      value={field.value ? String(field.value) : undefined}
                      onValueChange={(v) => field.onChange(Number(v))}
                    >
                      <FormControl>
                        <SelectTrigger className={inputCls}>
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
                    <FormLabel className={fieldLabel}>金額</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={0}
                        className={inputCls}
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
            </div>

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
              name="memo"
              render={({ field }) => (
                <FormItem>
                  <FormLabel className={fieldLabel}>
                    メモ{' '}
                    <span className="font-medium text-muted-foreground">
                      (任意)
                    </span>
                  </FormLabel>
                  <FormControl>
                    <Textarea
                      rows={3}
                      className="rounded-input bg-white"
                      {...field}
                      value={field.value ?? ''}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            {form.formState.errors.root && (
              <p className="text-sm text-destructive">
                {form.formState.errors.root.message}
              </p>
            )}

            <div className="flex gap-2.5 pt-1">
              <button
                type="submit"
                className={pillPrimary}
                disabled={mut.isPending}
              >
                {isEdit ? '更新する' : '追加する'}
              </button>
              <button
                type="button"
                className={pillCancel}
                onClick={() => navigate(`/incomes/${year}/${month}`)}
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

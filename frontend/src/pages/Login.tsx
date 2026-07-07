import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { z } from 'zod'
import { login } from '@/api/auth'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { card, fieldLabel, pillPrimary } from '@/lib/ui'
import { setTokens } from '@/lib/auth'

const schema = z.object({
  username: z.string().min(1, 'ユーザー名は必須です'),
  password: z.string().min(1, 'パスワードは必須です'),
})

type FormValues = z.infer<typeof schema>

export default function Login() {
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const next = params.get('next') || '/'

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { username: '', password: '' },
  })

  const mut = useMutation({
    mutationFn: (v: FormValues) => login(v.username, v.password),
    onSuccess: (data) => {
      setTokens(data.access, data.refresh)
      navigate(next, { replace: true })
    },
    onError: () => {
      form.setError('root', {
        type: 'server',
        message: 'ユーザー名またはパスワードが違います',
      })
    },
  })

  return (
    <div className="flex min-h-svh items-center justify-center bg-background p-4">
      <div className={`${card} w-full max-w-[380px] p-[30px]`}>
        <div className="mb-6 flex flex-col items-center gap-2.5">
          <img
            src="/icon-rounded-96.png"
            alt="INEX"
            className="size-11 rounded-[13px]"
          />
          <div className="text-[18px] font-extrabold">INEX にログイン</div>
          <div className="text-[12.5px] text-muted-foreground">
            わが家の家計簿へおかえりなさい
          </div>
        </div>
        <Form {...form}>
          <form
            className="grid gap-3.5"
            onSubmit={form.handleSubmit((v) => {
              form.clearErrors('root')
              mut.mutate(v)
            })}
          >
            <FormField
              control={form.control}
              name="username"
              render={({ field }) => (
                <FormItem>
                  <FormLabel className={fieldLabel}>ユーザー名</FormLabel>
                  <FormControl>
                    <Input
                      autoComplete="username"
                      autoFocus
                      className="h-[42px] rounded-input bg-white"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="password"
              render={({ field }) => (
                <FormItem>
                  <FormLabel className={fieldLabel}>パスワード</FormLabel>
                  <FormControl>
                    <Input
                      type="password"
                      autoComplete="current-password"
                      className="h-[42px] rounded-input bg-white"
                      {...field}
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
            <button
              type="submit"
              className={`${pillPrimary} mt-1 h-11 w-full`}
              disabled={mut.isPending}
            >
              {mut.isPending ? 'ログイン中...' : 'ログイン'}
            </button>
          </form>
        </Form>
      </div>
    </div>
  )
}

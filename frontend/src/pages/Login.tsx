import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { z } from 'zod'
import { login } from '@/api/auth'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
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
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <img src="/icon.png" alt="INEX" className="h-6 w-auto" />
            INEX にログイン
          </CardTitle>
        </CardHeader>
        <CardContent>
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
                name="username"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>ユーザー名</FormLabel>
                    <FormControl>
                      <Input autoComplete="username" autoFocus {...field} />
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
                    <FormLabel>パスワード</FormLabel>
                    <FormControl>
                      <Input
                        type="password"
                        autoComplete="current-password"
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
              <Button type="submit" className="w-full" disabled={mut.isPending}>
                {mut.isPending ? 'ログイン中...' : 'ログイン'}
              </Button>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  )
}

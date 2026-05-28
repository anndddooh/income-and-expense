import type { FieldValues, Path, UseFormSetError } from 'react-hook-form'

/**
 * DRFのバリデーションエラーをreact-hook-formのsetErrorに反映する。
 *
 * DRFは { field: ["メッセージ1", "メッセージ2"], non_field_errors: [...] } を返す。
 * 既知のフィールドならそこに、未知フィールドはフォーム全体のエラー (戻り値) で返す。
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function applyServerErrors(
  err: unknown,
  setError: UseFormSetError<any>,
  knownFields: readonly string[]
): string | null {
  type AxiosLike = {
    response?: { data?: unknown }
    message?: string
  }
  const ax = err as AxiosLike
  const data = ax?.response?.data

  if (data && typeof data === 'object' && !Array.isArray(data)) {
    const record = data as Record<string, unknown>
    let rootMessage: string | null = null
    const knownSet = new Set(knownFields)

    for (const [key, value] of Object.entries(record)) {
      const msg = Array.isArray(value) ? value.join(' ') : String(value)
      if (knownSet.has(key)) {
        setError(key as Path<FieldValues>, { type: 'server', message: msg })
      } else {
        rootMessage = rootMessage ? `${rootMessage}\n${msg}` : msg
      }
    }
    return rootMessage
  }

  return ax?.message ?? String(err)
}

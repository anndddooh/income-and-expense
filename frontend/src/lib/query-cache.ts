import type { QueryClient, QueryKey } from '@tanstack/react-query'

/**
 * 編集画面の詳細クエリ用 `initialData` オプションを作る。
 *
 * 一覧画面から遷移した場合は一覧のキャッシュに同じ行が既にあるので、
 * それを初期値にして詳細APIの応答待ちをなくす（応答は裏で再取得して上書き）。
 * 一覧は配列か `{ results: [...] }`（収入/支出）のどちらにも対応する。
 */
export function initialFromList<T extends { id: number }>(
  qc: QueryClient,
  listKey: QueryKey,
  id: number | undefined
) {
  return {
    initialData: () => {
      const data = qc.getQueryData<T[] | { results: T[] }>(listKey)
      const rows = Array.isArray(data) ? data : data?.results
      return rows?.find((r) => r.id === id)
    },
    initialDataUpdatedAt: () => qc.getQueryState(listKey)?.dataUpdatedAt,
  }
}

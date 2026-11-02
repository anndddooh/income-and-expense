import { Skeleton } from '@/components/ui/skeleton'

/** 編集フォームの既存値を復元するまでの間、フォームの代わりに出すプレースホルダ。 */
export default function FormSkeleton({ rows = 3 }: { rows?: number }) {
  return (
    <div className="grid gap-4" aria-busy="true" aria-label="読み込み中">
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="grid gap-4 sm:grid-cols-2">
          {[0, 1].map((j) => (
            <div key={j} className="grid gap-1.5">
              <Skeleton className="h-4 w-16" />
              <Skeleton className="h-[42px] rounded-input" />
            </div>
          ))}
        </div>
      ))}
      <div className="flex gap-2.5 pt-1">
        <Skeleton className="h-10 w-28 rounded-full" />
        <Skeleton className="h-10 w-28 rounded-full" />
      </div>
    </div>
  )
}

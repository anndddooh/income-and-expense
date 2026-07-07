import { useState } from 'react'
import { Menu, Settings as SettingsIcon } from 'lucide-react'
import {
  Link,
  Outlet,
  useLocation,
  useNavigate,
  useParams,
} from 'react-router-dom'
import { cn } from '@/lib/utils'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet'
import { todayYearMonth } from '@/util/date'

type NavItem = {
  label: string
  chevron?: boolean
  to: (year: number, month: number) => string
  match: (pathname: string) => boolean
}

const NAV: NavItem[] = [
  {
    label: 'ホーム',
    to: (y, m) => `/dashboard/${y}/${m}`,
    match: (p) => p === '/' || p.startsWith('/dashboard'),
  },
  {
    label: '収入',
    to: (y, m) => `/incomes/${y}/${m}`,
    match: (p) => p.startsWith('/incomes'),
  },
  {
    label: '支出',
    to: (y, m) => `/expenses/${y}/${m}`,
    match: (p) => p.startsWith('/expenses'),
  },
  {
    label: '残高',
    to: (y, m) => `/balance/${y}/${m}`,
    match: (p) => p.startsWith('/balance'),
  },
  {
    label: 'ローン',
    to: (y, m) => `/loans/${y}/${m}`,
    match: (p) => p.startsWith('/loans'),
  },
  {
    label: '必要額',
    chevron: true,
    to: (y, m) => `/requires/${y}/${m}`,
    match: (p) =>
      p.startsWith('/requires') ||
      p.startsWith('/account_require') ||
      p.startsWith('/method_require'),
  },
  {
    label: 'シミュレーター',
    to: () => '/scenarios',
    match: (p) => p.startsWith('/scenarios'),
  },
]

function useCurrentYearMonth() {
  const { year, month } = useParams<{ year?: string; month?: string }>()
  const now = todayYearMonth()
  return {
    year: year ? Number(year) : now.year,
    month: month ? Number(month) : now.month,
  }
}

const CURRENT_YEAR = todayYearMonth().year
const YEAR_OPTIONS = Array.from({ length: 101 }, (_, i) => CURRENT_YEAR - 50 + i)
const MONTH_OPTIONS = Array.from({ length: 12 }, (_, i) => i + 1)

export default function AppLayout() {
  const location = useLocation()
  const navigate = useNavigate()
  const { year, month } = useCurrentYearMonth()
  const [menuOpen, setMenuOpen] = useState(false)

  const seg = location.pathname.split('/').filter(Boolean)
  const currentBase = seg[0] ? `/${seg[0]}` : '/dashboard'
  const isMonthScoped = NAV.some(
    (n) => n.match(location.pathname) && n.label !== 'シミュレーター',
  )

  const goTo = (y: number, m: number) => {
    const base = isMonthScoped ? currentBase : '/dashboard'
    navigate(`${base}/${y}/${m}`)
  }

  const shift = (delta: number) => {
    let y = year
    let m = month + delta
    if (m < 1) {
      y -= 1
      m = 12
    } else if (m > 12) {
      y += 1
      m = 1
    }
    goTo(y, m)
  }

  return (
    <div className="min-h-svh bg-background text-foreground">
      <header className="sticky top-0 z-20 border-b border-border bg-card">
        <div className="flex h-[60px] items-center gap-3 px-4 md:gap-7 md:px-7">
          {/* logo */}
          <Link to="/" className="flex shrink-0 items-center gap-2.5">
            <img
              src="/icon-rounded-96.png"
              alt="INEX"
              className="size-7 rounded-[8px]"
            />
            <span className="text-[15px] font-extrabold tracking-wide">
              INEX
            </span>
          </Link>

          {/* inline nav pills (desktop) */}
          <nav className="hidden flex-1 items-center gap-1 overflow-x-auto md:flex [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {NAV.map((item) => {
              const active = item.match(location.pathname)
              return (
                <Link
                  key={item.label}
                  to={item.to(year, month)}
                  className={cn(
                    'inline-flex h-[34px] shrink-0 items-center gap-1 rounded-full px-3.5 text-[13.5px] transition-colors',
                    active
                      ? 'bg-primary-soft font-bold text-primary-strong'
                      : 'font-medium text-muted-foreground-2 hover:bg-primary-soft/50',
                  )}
                >
                  {item.label}
                  {item.chevron && (
                    <span className="text-[10px] text-muted-foreground">▾</span>
                  )}
                </Link>
              )
            })}
          </nav>

          {/* spacer on mobile so month pill/menu go right */}
          <div className="flex-1 md:hidden" />

          {/* month pill */}
          <div className="flex h-9 shrink-0 items-center gap-1 rounded-full border border-input px-2 text-[13px] font-bold tabular-nums">
            <button
              type="button"
              onClick={() => shift(-1)}
              aria-label="前月"
              className="px-1 text-base leading-none text-primary-strong"
            >
              ‹
            </button>
            <Popover>
              <PopoverTrigger asChild>
                <button
                  type="button"
                  aria-label="年月を選択"
                  className="tabular-nums"
                >
                  {year}年{month}月
                </button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-3" align="center">
                <div className="flex items-center gap-2">
                  <Select
                    value={String(year)}
                    onValueChange={(v) => goTo(Number(v), month)}
                  >
                    <SelectTrigger className="w-[100px]" aria-label="年">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {YEAR_OPTIONS.map((y) => (
                        <SelectItem key={y} value={String(y)}>
                          {y}年
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select
                    value={String(month)}
                    onValueChange={(v) => goTo(year, Number(v))}
                  >
                    <SelectTrigger className="w-[80px]" aria-label="月">
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
                </div>
              </PopoverContent>
            </Popover>
            <button
              type="button"
              onClick={() => shift(1)}
              aria-label="次月"
              className="px-1 text-base leading-none text-primary-strong"
            >
              ›
            </button>
          </div>

          {/* settings (desktop) */}
          <Link
            to="/settings"
            aria-label="設定"
            className="hidden shrink-0 text-muted-foreground transition-colors hover:text-foreground md:inline-flex"
          >
            <SettingsIcon className="size-[18px]" />
          </Link>

          {/* mobile menu */}
          <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
            <SheetTrigger asChild>
              <button
                type="button"
                aria-label="メニュー"
                className="inline-flex size-9 shrink-0 items-center justify-center rounded-full text-muted-foreground-2 transition-colors hover:bg-primary-soft/50 md:hidden"
              >
                <Menu className="size-5" />
              </button>
            </SheetTrigger>
            <SheetContent side="right" className="w-[260px] bg-card p-0">
              <SheetHeader className="border-b border-border px-4 py-4">
                <SheetTitle className="flex items-center gap-2.5 text-left">
                  <img
                    src="/icon-rounded-96.png"
                    alt="INEX"
                    className="size-7 rounded-[8px]"
                  />
                  <span className="text-[15px] font-extrabold">INEX</span>
                </SheetTitle>
              </SheetHeader>
              <nav className="flex flex-col gap-1 p-3">
                {NAV.map((item) => {
                  const active = item.match(location.pathname)
                  return (
                    <Link
                      key={item.label}
                      to={item.to(year, month)}
                      onClick={() => setMenuOpen(false)}
                      className={cn(
                        'flex h-11 items-center rounded-full px-4 text-[15px] transition-colors',
                        active
                          ? 'bg-primary-soft font-bold text-primary-strong'
                          : 'font-medium text-muted-foreground-2 hover:bg-primary-soft/50',
                      )}
                    >
                      {item.label}
                    </Link>
                  )
                })}
                <Link
                  to="/settings"
                  onClick={() => setMenuOpen(false)}
                  className={cn(
                    'mt-1 flex h-11 items-center gap-2 rounded-full px-4 text-[15px] transition-colors',
                    location.pathname.startsWith('/settings')
                      ? 'bg-primary-soft font-bold text-primary-strong'
                      : 'font-medium text-muted-foreground-2 hover:bg-primary-soft/50',
                  )}
                >
                  <SettingsIcon className="size-[18px]" />
                  設定
                </Link>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </header>

      <main className="mx-auto max-w-[1280px] px-4 py-6 md:px-7 md:py-8">
        <Outlet />
      </main>
    </div>
  )
}

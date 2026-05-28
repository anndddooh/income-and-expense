import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from 'recharts'
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart'
import type { TrendMonth } from '@/api/trends'

const chartConfig: ChartConfig = {
  income: {
    label: '収入',
    color: 'var(--chart-1)',
  },
  expense: {
    label: '支出',
    color: 'var(--chart-2)',
  },
}

export default function TrendChart({ data }: { data: TrendMonth[] }) {
  const chartData = data.map((m) => ({
    label: `${m.year}/${m.month}`,
    income: m.income,
    expense: m.expense,
  }))

  return (
    <ChartContainer config={chartConfig} className="h-[300px] w-full">
      <BarChart data={chartData}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="label" tickLine={false} axisLine={false} />
        <YAxis
          tickFormatter={(v: number) =>
            v >= 10000 ? `${Math.round(v / 10000)}万` : String(v)
          }
          tickLine={false}
          axisLine={false}
          width={50}
        />
        <ChartTooltip
          content={
            <ChartTooltipContent
              formatter={(value) => `¥${Number(value).toLocaleString()}`}
            />
          }
        />
        <ChartLegend content={<ChartLegendContent />} />
        <Bar dataKey="income" fill="var(--color-income)" radius={4} />
        <Bar dataKey="expense" fill="var(--color-expense)" radius={4} />
      </BarChart>
    </ChartContainer>
  )
}

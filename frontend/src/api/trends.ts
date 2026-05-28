import { api } from './client'

export type TrendMonth = {
  year: number
  month: number
  income: number
  expense: number
}

export type TrendResponse = {
  months: TrendMonth[]
}

export const fetchTrends = async (
  months: number,
  endYear: number,
  endMonth: number
) => {
  const { data } = await api.get<TrendResponse>('/trends/', {
    params: { months, end_year: endYear, end_month: endMonth },
  })
  return data
}

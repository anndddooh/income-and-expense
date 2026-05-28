import { api } from './client'

export type TemplateExpense = {
  id: number
  template_name: string
  name: string
  date_type: 'today' | 'later'
  pay_day: number | null
  limit_day_of_this_month: number | null
  method: number
  method_name: string
  state: number
  pay_date: string
}

export const fetchTemplateExpenses = async () => {
  const { data } = await api.get<TemplateExpense[]>('/template_expenses/')
  return data
}

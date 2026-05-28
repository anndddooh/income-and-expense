import { api } from './client'
import type { Income, IncomeInput } from './types'

export type IncomeListResponse = {
  results: Income[]
  prev_balance: number
}

export const fetchIncomes = async (year: number, month: number) => {
  const { data } = await api.get<IncomeListResponse>('/incomes/', { params: { year, month } })
  return data
}

export const fetchIncome = async (id: number) => {
  const { data } = await api.get<Income>(`/incomes/${id}/`)
  return data
}

export const createIncome = async (input: IncomeInput) => {
  const { data } = await api.post<Income>('/incomes/', input)
  return data
}

export const updateIncome = async (id: number, input: IncomeInput) => {
  const { data } = await api.put<Income>(`/incomes/${id}/`, input)
  return data
}

export const deleteIncome = async (id: number) => {
  await api.delete(`/incomes/${id}/`)
}

export const addDefaultIncomes = async (year: number, month: number) => {
  const { data } = await api.post<{ added: number }>(
    '/incomes/add_defaults/',
    null,
    { params: { year, month } }
  )
  return data
}

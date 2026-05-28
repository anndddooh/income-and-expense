import { api } from './client'
import type { StateValue } from './types'

export type DefaultExpense = {
  id: number
  name: string
  pay_day: number
  method: number
  method_name: string
  account: { id: number; user: string; bank: string }
  amount: number
  formed_amount: string
  state: StateValue
  state_label: string
  months: number[]
}

export type DefaultExpenseInput = {
  name: string
  pay_day: number
  method: number
  amount: number
  state: StateValue
  months: number[]
}

export const fetchDefaultExpenses = async () => {
  const { data } = await api.get<DefaultExpense[]>('/default_expenses/')
  return data
}

export const fetchDefaultExpense = async (id: number) => {
  const { data } = await api.get<DefaultExpense>(`/default_expenses/${id}/`)
  return data
}

export const createDefaultExpense = async (input: DefaultExpenseInput) => {
  const { data } = await api.post<DefaultExpense>('/default_expenses/', input)
  return data
}

export const updateDefaultExpense = async (
  id: number,
  input: DefaultExpenseInput,
) => {
  const { data } = await api.put<DefaultExpense>(
    `/default_expenses/${id}/`,
    input,
  )
  return data
}

export const deleteDefaultExpense = async (id: number) => {
  await api.delete(`/default_expenses/${id}/`)
}

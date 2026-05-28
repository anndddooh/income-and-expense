import { api } from './client'
import type { StateValue } from './types'

export type DefaultIncome = {
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

export type DefaultIncomeInput = {
  name: string
  pay_day: number
  method: number
  amount: number
  state: StateValue
  months: number[]
}

export const fetchDefaultIncomes = async () => {
  const { data } = await api.get<DefaultIncome[]>('/default_incomes/')
  return data
}

export const fetchDefaultIncome = async (id: number) => {
  const { data } = await api.get<DefaultIncome>(`/default_incomes/${id}/`)
  return data
}

export const createDefaultIncome = async (input: DefaultIncomeInput) => {
  const { data } = await api.post<DefaultIncome>('/default_incomes/', input)
  return data
}

export const updateDefaultIncome = async (
  id: number,
  input: DefaultIncomeInput,
) => {
  const { data } = await api.put<DefaultIncome>(
    `/default_incomes/${id}/`,
    input,
  )
  return data
}

export const deleteDefaultIncome = async (id: number) => {
  await api.delete(`/default_incomes/${id}/`)
}

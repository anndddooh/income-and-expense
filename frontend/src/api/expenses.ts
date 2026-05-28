import { api } from './client'
import type { Income as Inex, IncomeInput as InexInput } from './types'

// Expenseは表示/入力フィールドがIncomeと同じなので型を流用
export type Expense = Inex
export type ExpenseInput = InexInput

export type ExpenseListResponse = {
  results: Expense[]
  balance: number
}

export const fetchExpenses = async (year: number, month: number) => {
  const { data } = await api.get<ExpenseListResponse>('/expenses/', {
    params: { year, month },
  })
  return data
}

export const fetchExpense = async (id: number) => {
  const { data } = await api.get<Expense>(`/expenses/${id}/`)
  return data
}

export const createExpense = async (input: ExpenseInput) => {
  const { data } = await api.post<Expense>('/expenses/', input)
  return data
}

export const updateExpense = async (id: number, input: ExpenseInput) => {
  const { data } = await api.put<Expense>(`/expenses/${id}/`, input)
  return data
}

export const deleteExpense = async (id: number) => {
  await api.delete(`/expenses/${id}/`)
}

export const addDefaultExpenses = async (year: number, month: number) => {
  const { data } = await api.post<{ added: number }>(
    '/expenses/add_defaults/',
    null,
    { params: { year, month } }
  )
  return data
}

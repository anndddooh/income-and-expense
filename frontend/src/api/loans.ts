import { api } from './client'
import type { StateValue } from './types'

export type Loan = {
  id: number
  name: string
  pay_day: number
  first_year: number
  first_month: number
  last_year: number
  last_month: number
  method: number
  method_name: string
  account: { id: number; user: string; bank: string }
  amount_first: number
  amount_from_second: number
  formed_amount_first: string
  formed_amount_from_second: string
  state: StateValue
  state_label: string
}

export type LoanInput = {
  name: string
  pay_day: number
  first_year: number
  first_month: number
  last_year: number
  last_month: number
  method: number
  amount_first: number
  amount_from_second: number
  state: StateValue
}

export const fetchLoans = async () => {
  const { data } = await api.get<Loan[]>('/loans/')
  return data
}

export const fetchLoan = async (id: number) => {
  const { data } = await api.get<Loan>(`/loans/${id}/`)
  return data
}

export const createLoan = async (input: LoanInput) => {
  const { data } = await api.post<Loan>('/loans/', input)
  return data
}

export const updateLoan = async (id: number, input: LoanInput) => {
  const { data } = await api.put<Loan>(`/loans/${id}/`, input)
  return data
}

export const deleteLoan = async (id: number) => {
  await api.delete(`/loans/${id}/`)
}

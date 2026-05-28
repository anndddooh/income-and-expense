import { api } from './client'

export type AccountRow = {
  id: number
  bank: string
  user: string
  balance: number
  formed_balance: string
}

export type BalanceSummary = {
  year: number
  month: number
  accounts: AccountRow[]
  balance_sum: number
  balance_on_db: number
  balance_diff: number
}

export type Account = {
  id: number
  bank: number
  user: number
  bank_name: string
  user_name: string
  balance: number
  formed_balance: string
}

export const fetchBalance = async (year: number, month: number) => {
  const { data } = await api.get<BalanceSummary>('/balance/', {
    params: { year, month },
  })
  return data
}

export const fetchAccount = async (id: number) => {
  const { data } = await api.get<Account>(`/accounts/${id}/`)
  return data
}

export const updateAccountBalance = async (
  id: number,
  balance: number
) => {
  const { data } = await api.patch<Account>(`/accounts/${id}/`, { balance })
  return data
}

import { api } from './client'

export type AccountRequireRow = {
  id: number
  user: string
  bank: string
  balance: number
  formed_balance: string
  require: number
  formed_require: string
  insufficient_amount: number
  formed_insufficient: string
  is_insufficient: boolean
}

export type AccountRequireSummary = {
  accounts: AccountRequireRow[]
  require_sum: number
  insufficient_sum: number
}

export type MethodRequireRow = {
  id: number
  name: string
  display_name: string
  require: number
  formed_require: string
}

export type MethodRequireSummary = {
  methods: MethodRequireRow[]
  require_sum: number
}

export const fetchAccountRequire = async (year: number, month: number) => {
  const { data } = await api.get<AccountRequireSummary>('/account_require/', {
    params: { year, month },
  })
  return data
}

export const fetchMethodRequire = async (year: number, month: number) => {
  const { data } = await api.get<MethodRequireSummary>('/method_require/', {
    params: { year, month },
  })
  return data
}

export const methodDone = async (
  methodId: number,
  year: number,
  month: number
) => {
  const { data } = await api.post<{ updated: number }>(
    `/methods/${methodId}/done/`,
    null,
    { params: { year, month } }
  )
  return data
}

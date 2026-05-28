export type StateValue = 0 | 1 | 2

export type Income = {
  id: number
  name: string
  pay_date: string
  method: number
  method_name: string
  account: { id: number; user: string; bank: string }
  amount: number
  formed_amount: string
  state: StateValue
  state_label: string
  memo: string | null
}

export type IncomeInput = {
  name: string
  pay_date: string
  method: number
  amount: number
  state: StateValue
  memo?: string | null
}

export type Method = {
  id: number
  name: string
  display_name: string
}

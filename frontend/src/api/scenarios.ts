import { api } from './client'
import type { ExpenseCategoryValue } from './default-expenses'

export type ScenarioItem = {
  id: number
  name: string
  pay_day: number
  method: number | null
  method_name: string | null
  amount: number
  category: ExpenseCategoryValue
  category_label: string
  is_required: boolean
  is_enabled: boolean
  months: number[]
}

export type Scenario = {
  id: number
  name: string
  note: string
  created_at: string
  updated_at: string
  items: ScenarioItem[]
  item_count: number
}

export type ScenarioInput = {
  name: string
  note?: string
}

export type ScenarioItemInput = {
  scenario: number
  name: string
  pay_day: number
  method?: number | null
  amount: number
  category: ExpenseCategoryValue
  is_required: boolean
  is_enabled: boolean
  months: number[]
}

export type SummaryBuckets = {
  fixed: number
  variable: number
  one_time: number
  total_expense: number
  required: number
  optional: number
}

export type ScenarioSummary = SummaryBuckets & {
  mode: 'monthly' | 'yearly'
  month?: number
  income: number
  balance: number
}

export type HistoryAverage = {
  name: string
  months: number
  average: number
  count: number
}

export const fetchScenarios = async () => {
  const { data } = await api.get<Scenario[]>('/scenarios/')
  return data
}

export const fetchScenario = async (id: number) => {
  const { data } = await api.get<Scenario>(`/scenarios/${id}/`)
  return data
}

export const createScenario = async (input: ScenarioInput) => {
  const { data } = await api.post<Scenario>('/scenarios/', input)
  return data
}

export const updateScenario = async (id: number, input: ScenarioInput) => {
  const { data } = await api.put<Scenario>(`/scenarios/${id}/`, input)
  return data
}

export const deleteScenario = async (id: number) => {
  await api.delete(`/scenarios/${id}/`)
}

export const copyFromDefaults = async (id: number) => {
  const { data } = await api.post<Scenario>(
    `/scenarios/${id}/copy_from_defaults/`,
  )
  return data
}

export const fetchScenarioSummary = async (
  id: number,
  mode: 'monthly' | 'yearly',
  month?: number,
) => {
  const params = new URLSearchParams({ mode })
  if (mode === 'monthly' && month != null) params.set('month', String(month))
  const { data } = await api.get<ScenarioSummary>(
    `/scenarios/${id}/summary/?${params.toString()}`,
  )
  return data
}

export const createScenarioItem = async (input: ScenarioItemInput) => {
  const { data } = await api.post<ScenarioItem>('/scenario_items/', input)
  return data
}

export const updateScenarioItem = async (
  id: number,
  input: ScenarioItemInput,
) => {
  const { data } = await api.put<ScenarioItem>(
    `/scenario_items/${id}/`,
    input,
  )
  return data
}

export const patchScenarioItem = async (
  id: number,
  patch: Partial<ScenarioItemInput>,
) => {
  const { data } = await api.patch<ScenarioItem>(
    `/scenario_items/${id}/`,
    patch,
  )
  return data
}

export const deleteScenarioItem = async (id: number) => {
  await api.delete(`/scenario_items/${id}/`)
}

export const fetchHistoryAverage = async (name: string, months = 3) => {
  const { data } = await api.get<HistoryAverage>(
    `/expenses/history_average/`,
    { params: { name, months } },
  )
  return data
}

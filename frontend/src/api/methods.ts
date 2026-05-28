import { api } from './client'
import type { Method } from './types'

export const fetchMethods = async () => {
  const { data } = await api.get<Method[]>('/methods/')
  return data
}

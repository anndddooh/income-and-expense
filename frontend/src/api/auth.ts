import axios from 'axios'

const baseURL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000/api'

export type LoginResponse = {
  access: string
  refresh: string
}

export const login = async (username: string, password: string) => {
  const { data } = await axios.post<LoginResponse>(
    `${baseURL}/auth/login/`,
    { username, password },
    { headers: { 'Content-Type': 'application/json' } }
  )
  return data
}

import axios, { AxiosError, type InternalAxiosRequestConfig } from 'axios'
import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setAccessToken,
} from '@/lib/auth'

const baseURL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000/api'

export const api = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = getAccessToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

let refreshPromise: Promise<string> | null = null

const refreshAccessToken = async (): Promise<string> => {
  const refresh = getRefreshToken()
  if (!refresh) throw new Error('no refresh token')
  const res = await axios.post<{ access: string }>(
    `${baseURL}/auth/refresh/`,
    { refresh },
    { headers: { 'Content-Type': 'application/json' } }
  )
  setAccessToken(res.data.access)
  return res.data.access
}

const redirectToLogin = () => {
  clearTokens()
  if (typeof window !== 'undefined' && window.location.pathname !== '/login') {
    const next = window.location.pathname + window.location.search
    window.location.href = `/login?next=${encodeURIComponent(next)}`
  }
}

api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const original = error.config as
      | (InternalAxiosRequestConfig & { _retry?: boolean })
      | undefined
    const status = error.response?.status
    const url = original?.url ?? ''

    if (
      status !== 401 ||
      !original ||
      original._retry ||
      url.includes('/auth/login/') ||
      url.includes('/auth/refresh/')
    ) {
      if (status === 401) redirectToLogin()
      return Promise.reject(error)
    }

    original._retry = true
    try {
      refreshPromise = refreshPromise ?? refreshAccessToken()
      const access = await refreshPromise
      refreshPromise = null
      original.headers.Authorization = `Bearer ${access}`
      return api(original)
    } catch (e) {
      refreshPromise = null
      redirectToLogin()
      return Promise.reject(e)
    }
  }
)

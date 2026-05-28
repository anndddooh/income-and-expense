const ACCESS_KEY = 'inex.access_token'
const REFRESH_KEY = 'inex.refresh_token'

export const getAccessToken = () => localStorage.getItem(ACCESS_KEY)
export const getRefreshToken = () => localStorage.getItem(REFRESH_KEY)

export const setTokens = (access: string, refresh: string) => {
  localStorage.setItem(ACCESS_KEY, access)
  localStorage.setItem(REFRESH_KEY, refresh)
}

export const setAccessToken = (access: string) => {
  localStorage.setItem(ACCESS_KEY, access)
}

export const clearTokens = () => {
  localStorage.removeItem(ACCESS_KEY)
  localStorage.removeItem(REFRESH_KEY)
}

export const isAuthenticated = () => !!getAccessToken()

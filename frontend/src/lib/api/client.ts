import axios from 'axios'

export const apiOrigin = import.meta.env.VITE_API_URL ?? 'http://localhost:8000'

export const apiClient = axios.create({
  baseURL: `${apiOrigin}/api/v1`,
  withCredentials: true,
  withXSRFToken: true,
  headers: {
    Accept: 'application/json',
  },
})

/** Sanctum SPA auth needs the CSRF cookie set once before the first mutating request. */
export async function ensureCsrfCookie(): Promise<void> {
  await axios.get(`${apiOrigin}/sanctum/csrf-cookie`, { withCredentials: true })
}

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Let callers decide how to react (e.g. redirect to /login); we only
      // normalize the rejection shape here rather than hard-redirecting, since
      // 401s are expected for public pages checking "am I logged in?".
    }
    return Promise.reject(error)
  },
)

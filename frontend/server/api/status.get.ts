// Route serveur Nuxt : interroge le backend Go via le reseau Docker interne
// (http://backend:8080). Permet un rendu serveur fonctionnel sans exposer la
// topologie interne au navigateur.
export default defineEventHandler(async () => {
  const base = useRuntimeConfig().internalApiUrl

  const safe = async <T>(path: string): Promise<T | { error: string }> => {
    try {
      return await $fetch<T>(`${base}${path}`, { timeout: 4000 })
    } catch (e: any) {
      return { error: e?.message ?? String(e) }
    }
  }

  const [health, telemetry, leaderboard, similar] = await Promise.all([
    safe('/api/health'),
    safe('/api/telemetry'),
    safe('/api/leaderboard'),
    safe('/api/similar?speed=0.9&braking=0.8&consistency=0.6'),
  ])

  return { fetchedAt: new Date().toISOString(), health, telemetry, leaderboard, similar }
})

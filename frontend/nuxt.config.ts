export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',
  devtools: { enabled: false },

  modules: ['@nuxtjs/tailwindcss'],

  runtimeConfig: {
    // Utilisee par le rendu serveur (reseau Docker interne).
    internalApiUrl: process.env.NUXT_INTERNAL_API_URL || 'http://backend:8080',
    public: {
      // Utilisee par le navigateur (port publie sur l'hote).
      apiUrl: process.env.NUXT_PUBLIC_API_URL || 'http://localhost:6602',
    },
  },

  vite: {
    server: {
      // Necessaire pour que le hot reload voie les ecritures faites
      // depuis l'hote a travers le bind mount Docker.
      watch: { usePolling: true, interval: 300 },
    },
  },
})

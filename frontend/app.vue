<script setup lang="ts">
const { data, pending, refresh } = await useFetch('/api/status')

const apiUrl = useRuntimeConfig().public.apiUrl
const ticking = ref(false)

// Appel direct navigateur -> backend Go : valide le port publie + le CORS.
async function sendTick() {
  ticking.value = true
  try {
    await $fetch(`${apiUrl}/api/telemetry/tick?driver=pilote-web`, { method: 'POST' })
    await refresh()
  } finally {
    ticking.value = false
  }
}

const deps = computed(() => (data.value?.health as any)?.dependencies ?? {})
const healthy = computed(() => (data.value?.health as any)?.status === 'healthy')
</script>

<template>
  <div class="min-h-screen bg-asphalt-900 text-slate-200 font-mono">
    <div class="mx-auto max-w-5xl px-6 py-10">
      <header class="flex items-baseline justify-between border-b border-asphalt-600 pb-4">
        <div>
          <h1 class="text-2xl font-bold tracking-tight text-white">projet-6TT</h1>
          <p class="text-sm text-slate-400">Nuxt 3 · Go · PostgreSQL/pgvector · Redis · Godot 4</p>
        </div>
        <span
          class="rounded-full px-3 py-1 text-xs font-semibold"
          :class="healthy ? 'bg-neon/15 text-neon' : 'bg-red-500/15 text-red-400'"
        >
          {{ healthy ? 'STACK OPERATIONNELLE' : 'STACK DEGRADEE' }}
        </span>
      </header>

      <!-- Dependances -->
      <section class="mt-8 grid gap-4 sm:grid-cols-3">
        <div
          v-for="(dep, name) in deps"
          :key="name"
          class="rounded-lg border border-asphalt-600 bg-asphalt-800 p-4"
        >
          <div class="flex items-center justify-between">
            <span class="text-sm font-semibold uppercase tracking-wide text-slate-300">{{ name }}</span>
            <span :class="dep.ok ? 'text-neon' : 'text-red-400'">{{ dep.ok ? '●' : '○' }}</span>
          </div>
          <p class="mt-2 truncate text-xs text-slate-500" :title="dep.detail || dep.error">
            {{ dep.detail || dep.error }}
          </p>
          <p v-if="dep.latency" class="mt-1 text-xs text-slate-600">{{ dep.latency }}</p>
        </div>
      </section>

      <div class="mt-8 grid gap-6 md:grid-cols-2">
        <!-- Redis -->
        <section class="rounded-lg border border-asphalt-600 bg-asphalt-800 p-5">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-300">
            Telemetrie temps reel <span class="text-slate-500">(Redis)</span>
          </h2>
          <p class="mt-3 text-4xl font-bold text-white">
            {{ (data?.telemetry as any)?.total_ticks ?? 0 }}
          </p>
          <p class="text-xs text-slate-500">ticks cumules</p>

          <ul class="mt-4 space-y-1 text-sm">
            <li
              v-for="d in (data?.telemetry as any)?.top_drivers ?? []"
              :key="d.driver"
              class="flex justify-between text-slate-400"
            >
              <span>{{ d.driver }}</span><span class="text-slate-500">{{ d.ticks }}</span>
            </li>
          </ul>

          <button
            class="mt-5 rounded bg-neon/90 px-4 py-2 text-sm font-semibold text-asphalt-900 hover:bg-neon disabled:opacity-40"
            :disabled="ticking"
            @click="sendTick"
          >
            {{ ticking ? 'envoi…' : 'Envoyer un tick' }}
          </button>
        </section>

        <!-- Postgres -->
        <section class="rounded-lg border border-asphalt-600 bg-asphalt-800 p-5">
          <h2 class="text-sm font-semibold uppercase tracking-wide text-slate-300">
            Meilleurs tours <span class="text-slate-500">(PostgreSQL)</span>
          </h2>
          <table class="mt-3 w-full text-sm">
            <tbody>
              <tr
                v-for="lap in (data?.leaderboard as any)?.laps ?? []"
                :key="lap.driver + lap.track"
                class="border-b border-asphalt-700 last:border-0"
              >
                <td class="py-1.5 text-slate-300">{{ lap.driver }}</td>
                <td class="py-1.5 text-slate-500">{{ lap.track }}</td>
                <td class="py-1.5 text-right text-white">{{ (lap.lap_time_ms / 1000).toFixed(3) }}s</td>
              </tr>
            </tbody>
          </table>

          <h3 class="mt-6 text-xs font-semibold uppercase tracking-wide text-slate-400">
            Styles proches <span class="text-slate-600">(pgvector · cosine)</span>
          </h3>
          <ul class="mt-2 space-y-1 text-sm">
            <li
              v-for="m in (data?.similar as any)?.matches ?? []"
              :key="'sim-' + m.driver"
              class="flex justify-between text-slate-400"
            >
              <span>{{ m.driver }}</span>
              <span class="text-slate-600">d={{ m.distance?.toFixed(4) }}</span>
            </li>
          </ul>
        </section>
      </div>

      <footer class="mt-8 flex items-center gap-4 text-xs text-slate-600">
        <button class="underline hover:text-slate-400" :disabled="pending" @click="refresh()">
          rafraichir
        </button>
        <span>API navigateur : {{ apiUrl }}</span>
        <span v-if="data?.fetchedAt">· {{ data.fetchedAt }}</span>
      </footer>
    </div>
  </div>
</template>

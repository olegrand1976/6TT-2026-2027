# 04 — API Go et dashboard Nuxt

## Objectif

Tracer le **flux dashboard** : SSR Nuxt, double URL d’API, endpoints Go.

## Prérequis

- Modules [01](../01-valider-la-stack/) et [03](../03-donnees-postgres-redis/) recommandés

## Durée

~35 minutes.

## Étapes

1. Schéma [`../_assets/flux-dashboard.svg`](../_assets/flux-dashboard.svg).
2. **curl côté « navigateur »** (port publié) :
   ```bash
   curl -s http://localhost:6602/api/health | jq .status
   curl -s -X POST "http://localhost:6602/api/telemetry/tick?driver=exemple04"
   curl -s http://localhost:6602/api/leaderboard | jq
   ```
3. **SSR Nuxt** (agrégat) :
   ```bash
   curl -s http://localhost:6603/api/status | jq '.health.status, .telemetry'
   ```
4. **Lecture ciblée du code** :
   - [`frontend/nuxt.config.ts`](../../frontend/nuxt.config.ts) — `NUXT_INTERNAL_API_URL` / `NUXT_PUBLIC_API_URL`
   - [`frontend/server/api/status.get.ts`](../../frontend/server/api/status.get.ts) — appels parallèles backend
   - [`frontend/app.vue`](../../frontend/app.vue) — tick bouton → `NUXT_PUBLIC_API_URL`
   - [`backend/main.go`](../../backend/main.go) — routes `/api/health`, `/api/telemetry`, `/api/similar`
5. Ouvrir http://localhost:6603 et corréler avec les réponses curl.

## Critères de réussite

- Vous expliquez pourquoi le SSR **ne peut pas** utiliser `localhost:6602` depuis le conteneur frontend sans passer par le port hôte (il utilise `backend:8080`).
- Le bouton tick fonctionne (CORS `*` en dev).

## Pièges

- Fusionner les deux URL API → SSR ou navigateur casse (guide §12).
- Node &lt; 24 sur le frontend → erreurs npm (`edgesOut`).

## Lien Rac6TT

[GUIDE-ELEVES §10–11](../../docs/GUIDE-ELEVES.md#10-api-backend) · [status.get.ts](../../frontend/server/api/status.get.ts).

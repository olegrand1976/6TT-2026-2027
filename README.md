# projet-6TT — environnement de test

Stack de développement conteneurisée pour un **jeu de course 2D multijoueur** :
API Go, dashboard Nuxt 3, PostgreSQL + `pgvector`, Redis, serveur Godot 4.7
headless et client HTML5.

Hot-reload partout (Air / Vite) : le code est monté depuis l’hôte.

| Public | Document |
|--------|----------|
| **Élèves 6TT** — structure, composants, pièges | **[docs/GUIDE-ELEVES.md](docs/GUIDE-ELEVES.md)** |
| Agents IA (Cursor / Claude) | [CLAUDE.md](CLAUDE.md) |

---

## Démarrage rapide

```bash
cp .env.example .env      # obligatoire — adapter le mot de passe
docker compose up -d --build
docker compose ps
```

> Sans `.env` complet, Compose utilise d’autres defaults (`game_user` / `game_db`).
> Toujours partir de `.env.example` (`game_admin` / `racing_game_db`).

Premier lancement : ~3–5 min (image Godot ~2 Go + npm).

**Checklist 1re séance** → [Guide §4](docs/GUIDE-ELEVES.md#4-première-séance-checklist).

| Service | URL / accès | Rôle |
|---------|-------------|------|
| Frontend | http://localhost:6603 | Dashboard Nuxt (santé, télémétrie, classement) |
| Jeu (web) | http://localhost:6605 | **Client jouable** (HTML5 via Caddy) |
| Backend | http://localhost:6602 | API Go |
| PostgreSQL | `localhost:6600` | Données + recherche vectorielle |
| Redis | `localhost:6601` | Compteurs temps réel |
| Godot WS | `ws://localhost:6604` | Serveur de jeu (WebSocket brut, pas HTTP) |
| Godot éditeur (noVNC) | http://localhost:6606/vnc.html | Profil Docker `editor` (voir ci-dessous) |

- Dashboard : bandeau **STACK OPERATIONNELLE** si Postgres, pgvector et Redis OK.
- Jeu : flèches pour conduire ; plusieurs onglets = multijoueur.
- Diagnostic WS : http://localhost:6605/diag.html

---

## Éditeur Godot dans Docker (port 6606)

Service **optionnel** (noVNC + Xvfb, dev labo uniquement) :

```bash
docker compose --profile editor up -d godot-editor
```

Puis http://localhost:6606/vnc.html — même projet monté que le serveur (`./godot`).
L’éditeur natif reste préférable : `godot --path godot -e`.

---

## Ports 6600–6606

Les ports classiques (`5432`, `6379`, `8080`, `3000`) sont souvent **déjà pris**
sur la machine de labo. Seuls les ports **hôte** sont remappés ; en réseau
Docker on garde `postgres:5432`, `redis:6379`, `backend:8080`, `godot:8999`.

Variables dans `.env` : `POSTGRES_PORT`, `REDIS_PORT`, `BACKEND_PORT`,
`FRONTEND_PORT`, `GODOT_PORT`, `WEBCLIENT_PORT`, `GODOT_EDITOR_PORT`.

Détail et schéma réseau → [Guide élèves §6](docs/GUIDE-ELEVES.md#6-réseau-docker-et-ports).

---

## Structure

```text
projet-6TT/
├── docs/GUIDE-ELEVES.md     # documentation pédagogique complète
├── docker-compose.yml
├── .env / .env.example
├── db/init/01-extensions.sql
├── backend/main.go          # API unique
├── frontend/                # Nuxt 3 + Tailwind
└── godot/                   # serveur + client + Caddyfile + export web
```

Arborescence détaillée → [Guide élèves §5](docs/GUIDE-ELEVES.md#5-structure-du-dépôt).

---

## Comment ça s’articule (résumé)

```text
postgres ─┐ healthy
          ├──> backend ──> frontend (SSR via http://backend:8080)
redis ────┘            └──> godot ──> webclient (statique + /ws)
```

**Deux URL d’API frontend** (ne pas fusionner) :

| Appelant | Variable | Valeur |
|----------|----------|--------|
| SSR Nitro | `NUXT_INTERNAL_API_URL` | `http://backend:8080` |
| Navigateur | `NUXT_PUBLIC_API_URL` | `http://localhost:6602` |

**Jeu** : le navigateur ouvre `ws://…:6605/ws` ; Caddy relaie vers `godot:8999`.
Ne pas viser le port 6604 depuis le navigateur par défaut.

---

## API (aperçu)

| Méthode | Route | Rôle |
|---------|-------|------|
| GET | `/healthz` | Liveness Docker |
| GET | `/api/health` | Postgres + pgvector + Redis |
| GET/POST | `/api/telemetry`… | Compteurs Redis |
| GET | `/api/leaderboard` | Tours (Postgres) |
| GET | `/api/similar` | Similarité cosinus (`pgvector`) |

Exemples et détails → [Guide élèves §10](docs/GUIDE-ELEVES.md#10-api-backend).

---

## Jeu Godot (aperçu)

Un seul projet, deux rôles (`main.gd`) : headless → serveur, sinon client.

```text
Main → Net (toujours) + Server | Client
```

- Autorité serveur : `submit_input` → simulation → `snapshot` (30 Hz).
- Après modif jeu : `./godot/export-web.sh`
- Éditeur hôte : `godot --path godot -e` (sans templates d’export)

Pièges WebSocket, nœud `Net`, reconnexion → [Guide élèves §9 et §12](docs/GUIDE-ELEVES.md#9-le-jeu-godot-en-détail).

---

## Commandes utiles

```bash
docker compose ps
docker compose logs -f backend
docker compose restart godot
./godot/export-web.sh

docker compose exec postgres psql -U game_admin -d racing_game_db
# (valeurs de .env.example — sinon : grep POSTGRES_ .env)
docker compose exec redis redis-cli

# Reset complet (détruit les données)
docker compose down -v && docker compose up -d --build

# Test client headless
godot --headless --path godot --quit-after 200 -- --client
```

---

## Points d’attention (essentiel)

1. **Toujours** `cp .env.example .env` (sinon defaults Compose ≠ example).
2. **Ne pas** revenir aux ports standards sur l’hôte.
3. **Ne pas** fusionner les deux URL d’API Nuxt.
4. **Node 24** minimum pour le frontend (npm 10 plante sur Nuxt).
5. Init SQL Postgres : uniquement à la **création du volume** (`down -v` pour rejouer).
6. Navigateur → jeu via **`/ws`**, pas `:6604` en direct.
7. Caddy strippe les cookies du handshake WS (limite ~4 Ko côté Godot).
8. Godot : `--path`, pas `--main-pack` ; ne pas monter le dossier des templates.

Liste complète → [Guide élèves §12](docs/GUIDE-ELEVES.md#12-points-dattention-pièges).

---

## Sécurité

`.env` est gitignored ; `.env.example` est versionné. Stack **dev local**
uniquement : ports BDD exposés, CORS `*`, hot-reload. Une prod demanderait
build multi-stage, CORS strict, ports BDD fermés.

---

## Versions

| | | | |
|--|--|--|--|
| PostgreSQL **18** + pgvector **0.8.6** | Redis **8.8** | Go **1.27.1** | |
| Node **24** / npm 11 | Nuxt **3.21.x** | Godot **4.7.2** | Caddy **2.11** |

Nuxt reste en **3.x** (migration 4 non faite). Patch runtime : vérifier via les
conteneurs. Détail → [Guide §16](docs/GUIDE-ELEVES.md#16-versions-de-référence).

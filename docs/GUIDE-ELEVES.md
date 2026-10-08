# Guide élèves — projet-6TT

Documentation pédagogique de l’environnement de test **projet-6TT** :
stack Docker d’un jeu de course 2D multijoueur, avec API Go, dashboard Nuxt,
PostgreSQL/`pgvector`, Redis, serveur Godot headless et client HTML5.

Ce guide décrit **la configuration telle qu’elle tourne aujourd’hui**, la
structure du dépôt, le rôle de chaque composant, et les **pièges déjà rencontrés**
lors de la mise en place.

Pour démarrer vite : [README.md](../README.md).  
Pour les agents IA (Cursor / Claude) : [CLAUDE.md](../CLAUDE.md).

---

## Sommaire

1. [Objectifs pédagogiques](#1-objectifs-pédagogiques)
2. [Vue d’ensemble](#2-vue-densemble)
3. [Démarrage](#3-démarrage)
4. [Première séance (checklist)](#4-première-séance-checklist)
5. [Structure du dépôt](#5-structure-du-dépôt)
6. [Réseau Docker et ports](#6-réseau-docker-et-ports)
7. [Composant par composant](#7-composant-par-composant)
8. [Flux de données](#8-flux-de-données)
9. [Le jeu Godot en détail](#9-le-jeu-godot-en-détail)
10. [API backend](#10-api-backend)
11. [Frontend Nuxt](#11-frontend-nuxt)
12. [Points d’attention (pièges)](#12-points-dattention-pièges)
13. [Valider et diagnostiquer](#13-valider-et-diagnostiquer)
14. [Graphify (graphe de code)](#14-graphify-graphe-de-code)
15. [Pistes de travail](#15-pistes-de-travail)
16. [Versions de référence](#16-versions-de-référence)

---

## 1. Objectifs pédagogiques

En travaillant sur ce dépôt, vous êtes amenés à comprendre :

- l’**orchestration** de plusieurs services (Compose, healthchecks, réseau interne) ;
- la différence entre **port hôte** et **port conteneur** ;
- un **backend Go** minimal (`net/http`, Postgres, Redis) ;
- un **frontend Nuxt 3** avec SSR et appels navigateur (deux URL d’API) ;
- une **recherche vectorielle** simple avec `pgvector` ;
- un **jeu multijoueur** Godot 4 (autorité serveur, RPC, WebSocket, export HTML5) ;
- le **proxy same-origin** (Caddy `/ws`) et pourquoi on l’utilise.

Ce n’est **pas** une stack de production : CORS ouvert, bases exposées, hot-reload.

---

## 2. Vue d’ensemble

Six services sur le réseau Docker `game-net` :

```text
                    ┌─────────────────────────────────────────────┐
  Navigateur        │  Hôte (ports publiés)                       │
                    │  6603 Nuxt │ 6605 Caddy │ 6602 API          │
                    └──────┬──────────┬────────────┬──────────────┘
                           │          │            │
         ┌─────────────────┼──────────┼────────────┼──────────────┐
         │  Docker network game-net   │            │              │
         │                 │          │            │              │
         │            frontend     webclient    backend           │
         │             :3000         :80         :8080            │
         │                 │          │            │              │
         │                 │     /ws proxy         ├─ postgres:5432
         │                 │          │            └─ redis:6379  │
         │                 │       godot:8999                     │
         └─────────────────┴──────────┴───────────────────────────┘
```

| Service     | Techno                       | Port hôte | Port interne | Rôle |
|-------------|------------------------------|-----------|--------------|------|
| `postgres`  | pgvector 0.8.6 / PostgreSQL 18 | 6600    | 5432         | Données + embeddings |
| `redis`     | Redis 8.8                    | 6601      | 6379         | Compteurs télémétrie |
| `backend`   | Go 1.27.1 + Air              | 6602      | 8080         | API HTTP |
| `frontend`  | Nuxt 3 + Tailwind (Node 24)  | 6603      | 3000         | Dashboard SSR |
| `godot`     | Godot 4.7.2 headless         | 6604      | 8999         | Serveur de jeu WS |
| `webclient` | Caddy 2.11                   | 6605      | 80           | Client HTML5 + `/ws` |
| `godot-editor` | noVNC (profil `editor`)   | 6606      | 6080         | Éditeur Godot dans le navigateur |

**Deux « faces » du projet :**

1. **Dashboard** (6603) — santé stack, Redis, classement, similarité pgvector.
2. **Jeu** (6605) — course 2D multijoueur dans le navigateur.

Aujourd’hui le jeu **ne pousse pas** encore ses scores vers l’API Go : Godot
reçoit `BACKEND_URL` en variable d’environnement et la journalise, mais le flux
live reste **WebSocket pur** (inputs / snapshots).

---

## 3. Démarrage

Prérequis : Docker + Docker Compose v2, ~4 Go libres (image Godot).

```bash
cp .env.example .env          # OBLIGATOIRE — adapter POSTGRES_PASSWORD
docker compose up -d --build
docker compose ps             # 5 healthchecks verts (godot : logs seulement)
```

> **Credentials :** partez toujours de `.env.example`
> (`POSTGRES_USER=game_admin`, `POSTGRES_DB=racing_game_db`).  
> Si `.env` est absent ou incomplet, Compose bascule sur ses *defaults internes*
> (`game_user` / `game_db` / `game_password`) — différents de l’example. Les
> commandes `psql` du guide et du README suivent l’example ; adaptez-les à
> *votre* `.env` (`grep POSTGRES_ .env`).

Premier build : **3–5 minutes** (image Godot ~2 Go, `npm ci` frontend).

Ensuite :

| URL | Action |
|-----|--------|
| http://localhost:6603 | Dashboard — bandeau **STACK OPERATIONNELLE** |
| http://localhost:6605 | Jouer (flèches) — plusieurs onglets = multi |
| http://localhost:6605/diag.html | Diagnostic WebSocket (proxy vs direct) |
| http://localhost:6606/vnc.html?autoconnect=true&resize=scale | Éditeur Godot noVNC plein écran (profil `editor`) |

### Installer Godot 4.7.2 en local (Linux, recommandé)

Version **identique** au conteneur (`barichello/godot-ci:4.7.2`) :

1. **Téléchargement officiel** — [godotengine.org/download](https://godotengine.org/download/linux/)  
   Choisir **Godot Engine – Standard** en **4.7.2** (fichier `.x86_64.zip` ou
   `.x86_64` selon l’offre), **pas** la variante « .NET » sauf si vous utilisez C#.
2. **Installation manuelle** :
   ```bash
   unzip Godot_v4.7.2-stable_linux.x86_64.zip
   chmod +x Godot_v4.7.2-stable_linux.x86_64
   mkdir -p ~/.local/bin
   ln -sf "$PWD/Godot_v4.7.2-stable_linux.x86_64" ~/.local/bin/godot
   ```
   Vérifier : `godot --version` → `4.7.2.stable…`
3. **Flatpak** (alternative) : `flatpak install flathub org.godotengine.Godot`
   puis vérifier la version (`flatpak run org.godotengine.Godot --version`).
4. **Depuis la racine du dépôt** (interface en français) :
   ```bash
   godot --path godot -e --language fr
   ```
   Pas besoin des templates d’export Web sur l’hôte (`./godot/export-web.sh` passe
   par Docker).

Le serveur Docker peut rester lancé : **F5** dans l’éditeur = client de plus
(`ws://127.0.0.1:6604`).

### Éditeur dans Docker (noVNC, sans install Godot)

```bash
docker compose --profile editor up -d godot-editor
# apres modif de godot/entrypoint-editor.sh ou Dockerfile.editor :
docker compose --profile editor up -d --build godot-editor
```

Ouvrir  
http://localhost:6606/vnc.html?autoconnect=true&resize=scale  
→ l’éditeur démarre en **plein écran** sur le bureau virtuel (pas de mot de passe
VNC). Dans noVNC : **Scaling mode → Local scaling** si la barre latérale masque
le canvas. Rendu logiciel (Xvfb) : plus lent que l’éditeur natif.

Après modif de scripts/scènes : `docker compose restart godot` si le serveur de
jeu doit recharger ; `./godot/export-web.sh` pour mettre à jour le client **6605**.

**Pavé numérique / Num Lock** : la session X force un état via `EDITOR_NUMLOCK`
(`on` par défaut dans `.env`) à chaque connexion noVNC. Si le comportement semble
inversé par rapport à votre clavier physique, essayez `EDITOR_NUMLOCK=off` puis
`docker compose --profile editor up -d --build godot-editor`, ou basculez
**Verr. Num** une fois dans le canvas (focus dans l’éditeur).

Checklist guidée de la 1re heure → [§4](#4-première-séance-checklist).

---

## 4. Première séance (checklist)

Objectif : vérifier que **toute** la stack répond, sans modifier le code.

1. **Préparer l’environnement**
   ```bash
   cp -n .env.example .env    # ne pas écraser un .env déjà rempli
   # éditer POSTGRES_PASSWORD si besoin
   docker compose up -d --build
   docker compose ps          # postgres, redis, backend, frontend, webclient = healthy
   ```
2. **Dashboard** — ouvrir http://localhost:6603  
   - bandeau **STACK OPERATIONNELLE**  
   - cliquer « Envoyer un tick » : le compteur Redis monte  
3. **API** — dans un terminal :
   ```bash
   curl -s http://localhost:6602/api/health | jq .status
   # attendu : "healthy"
   ```
4. **Jeu** — ouvrir http://localhost:6605 dans **deux** onglets  
   - flèches pour conduire ; les deux voitures sont visibles  
5. **Diagnostic WS** — http://localhost:6605/diag.html  
   - chemin proxy `/ws` OK  
6. **Logs**
   ```bash
   docker compose logs --tail=30 godot      # [6TT] Pilote connecte…
   docker compose logs --tail=20 webclient  # accès / et /ws
   ```

Si une étape échoue → [§12 pièges](#12-points-dattention-pièges) et
[§13 validation](#13-valider-et-diagnostiquer).

---

## 5. Structure du dépôt

```text
projet-6TT/
├── README.md                 # entrée rapide
├── CLAUDE.md                 # règles pour agents IA
├── docs/
│   └── GUIDE-ELEVES.md       # ce guide
├── docker-compose.yml        # 6 services, healthchecks, volumes
├── .env / .env.example       # identifiants + ports hôte
├── db/init/
│   └── 01-extensions.sql     # vector + table démo (1re création volume)
├── backend/
│   ├── Dockerfile            # golang:1.27.1-alpine + Air
│   ├── .air.toml
│   ├── go.mod / go.sum
│   └── main.go               # toute l’API
├── frontend/
│   ├── Dockerfile            # node:24-alpine
│   ├── nuxt.config.ts        # dual URL API + polling Vite
│   ├── app.vue               # dashboard
│   └── server/api/status.get.ts
├── godot/
│   ├── Dockerfile            # barichello/godot-ci:4.7.2
│   ├── project.godot
│   ├── main.tscn / main.gd   # choix serveur | client
│   ├── net.gd                # RPC + tick 30 Hz
│   ├── server/server.gd
│   ├── client/               # rendu, HUD, reconnexion
│   ├── shared/               # physique, track, CarState
│   ├── Caddyfile             # utilisé par le service webclient
│   ├── export-web.sh
│   ├── export_presets.cfg
│   ├── web-extra/diag.html
│   └── build/web/            # build HTML5 (généré, gitignored)
└── graphify-out/             # graphe de code local (généré, optionnel)
```

Fichiers **générés / locaux** à ne pas versionner inutilement : `.env`,
`godot/build/`, `godot/.godot/`, `frontend/node_modules/`, `frontend/.nuxt/`,
`backend/tmp/`, `graphify-out/`.

---

## 6. Réseau Docker et ports

### Pourquoi 6600–6606 ?

Sur la machine de labo, les ports classiques (`5432`, `6379`, `8080`, `3000`)
étaient déjà pris par d’autres stacks. Compose aurait échoué avec
`port is already allocated`.

Le bloc **6600–6606** regroupe les services de façon lisible (6606 = profil
`editor` optionnel). Seuls les
ports **publiés sur l’hôte** changent. À l’intérieur de Docker, on garde les
ports standards et on parle par **nom de service** :

```text
postgres:5432   redis:6379   backend:8080   godot:8999
```

Pilotage exclusif via `.env` :

```env
POSTGRES_PORT=6600
REDIS_PORT=6601
BACKEND_PORT=6602
FRONTEND_PORT=6603
GODOT_PORT=6604
WEBCLIENT_PORT=6605
GODOT_EDITOR_PORT=6606
```

Après modification : `docker compose up -d` (pas besoin de rebuild sauf change
d’image / Dockerfile).

### Ordre de démarrage

Compose attend les **healthchecks**, pas seulement `depends_on` :

```text
postgres ─┐ healthy
          ├──> backend (healthz) ──> frontend
redis ────┘                      └──> godot ──> webclient
```

`godot` **n’a pas** de healthcheck HTTP (image sans outil adapté) : on regarde
les logs `[6TT]`.

### PostgreSQL 18 — point de montage

Les images officielles 18+ stockent les données sous `/var/lib/postgresql`
(pas `/var/lib/postgresql/data`). Avec l’ancien chemin, le conteneur refuse de
démarrer. Les données vont dans un sous-dossier `18/docker`, compatible
`pg_upgrade --link` plus tard.

---

## 7. Composant par composant

### 7.1 Postgres + pgvector (`postgres`)

- Image : `pgvector/pgvector:0.8.6-pg18`
- Init : `db/init/01-extensions.sql` monté dans `/docker-entrypoint-initdb.d`
- **Exécuté une seule fois**, à la **création du volume** `postgres_data`
- Contenu :
  - `CREATE EXTENSION vector`
  - table `telemetry_samples` (driver, track, lap_time_ms, `embedding vector(3)`)
  - index HNSW cosinus
  - 4 lignes de démo (alpha, bravo, charlie, delta)

Embedding = style de pilotage : `[vitesse_moy, agressivité_freinage, régularité]`.

Pour **rejouer** l’init après modification du SQL :

```bash
docker compose down -v && docker compose up -d
```

Un simple `restart` **ne suffit pas**.

Accès :

```bash
# Remplacer user/db par les valeurs de VOTRE .env (voir grep POSTGRES_ .env)
docker compose exec postgres psql -U game_admin -d racing_game_db
```

### 7.2 Redis (`redis`)

- Image : `redis:8.8-alpine`, AOF activé (`--appendonly yes`)
- Clés utilisées par le backend :
  - `6tt:telemetry:ticks` — compteur global (INCR)
  - `6tt:telemetry:drivers` — sorted set (ZINCRBY / ZREVRANGE)

Rôle pédagogique : montrer un cache / compteur **temps réel** à côté de Postgres
(données persistantes / vectorielles).

```bash
docker compose exec redis redis-cli
> GET 6tt:telemetry:ticks
> ZREVRANGE 6tt:telemetry:drivers 0 9 WITHSCORES
```

### 7.3 Backend Go (`backend`)

- Un seul fichier applicatif : [`backend/main.go`](../backend/main.go)
- Pas de framework : `net/http` + patterns Go 1.22+ (`"GET /api/health"`)
- Clients : `pgxpool` (Postgres), `go-redis/v9`
- Hot-reload : **Air** (~4 s après save d’un `.go`)
- Code monté : `./backend` → `/app`
- CORS : `CORS_ORIGIN=*` (dev)

Liveness vs readiness :

| Route | Usage |
|-------|--------|
| `GET /healthz` | Healthcheck Docker — **ne touche aucune dépendance** |
| `GET /api/health` | Vérifie vraiment Postgres, extension `vector`, Redis |

Voir [§10 API backend](#10-api-backend).

### 7.4 Frontend Nuxt (`frontend`)

- Node **24** (npm 11) — obligatoire (voir pièges)
- Nuxt **3.x** (pas Nuxt 4)
- [`app.vue`](../frontend/app.vue) : dashboard
- [`server/api/status.get.ts`](../frontend/server/api/status.get.ts) : agrège 4
  appels backend en SSR
- Volumes anonymes sur `node_modules` et `.nuxt` pour ne pas écraser l’image
  avec le bind mount hôte
- Vite `usePolling` : indispensable derrière Docker

Voir [§11 Frontend Nuxt](#11-frontend-nuxt).

### 7.5 Godot serveur (`godot`)

- Image CI `barichello/godot-ci:4.7.2` avec templates d’export (~1.3 Go)
- CMD : `godot --headless --path /project` (pas `--main-pack`)
- `ENTRYPOINT []` pour que le `CMD` Compose soit respecté
- Écoute WebSocket `0.0.0.0:8999` (`GAME_PORT`)
- Projet monté : `./godot` → `/project`
- **Pas** de volume sur `/root/.local/share/godot` (sinon copie inutile des templates)

### 7.6 Client web Caddy (`webclient`)

- Image `caddy:2.11-alpine`
- Sert `godot/build/web` en lecture seule
- [`godot/Caddyfile`](../godot/Caddyfile) :
  - fichiers statiques + `Cache-Control: no-store`
  - COOP/COEP (prêt pour export *threads*)
  - handshake WebSocket sur `/ws` → `godot:8999` avec **strip** de cookies /
    headers lourds ; requête HTTP simple sur `/ws` → **426** (pas un 502 Godot)

### 7.7 Éditeur Godot noVNC (`godot-editor`, profil `editor`)

- Image dérivée de `godot-ci:4.7.2` + Xvfb + noVNC (`godot/Dockerfile.editor`)
- **Non** démarré par `docker compose up -d` seul : `--profile editor`
- Port hôte **6606** → noVNC **6080**
- **Persistance** :
  - `./godot` → `/project` : scènes, scripts, `project.godot`, cache `.godot/`
    (tout ce que vous enregistrez dans l’éditeur est sur le disque hôte)
  - `./godot/.docker/editor-home` → prefs éditeur (langue, disposition des panneaux)
- Dans `.env`, aligner `HOST_UID` / `HOST_GID` sur `id -u` / `id -g` pour que les
  fichiers créés restent modifiables hors Docker
- Dev labo uniquement (VNC sans mot de passe)

Régénérer le build après modif jeu :

```bash
./godot/export-web.sh
```

---

## 8. Flux de données

### Dashboard (Nuxt ↔ Go ↔ Postgres/Redis)

```text
Navigateur
  │  useFetch('/api/status')          → Nitro (conteneur frontend)
  │                                     └─ NUXT_INTERNAL_API_URL
  │                                        http://backend:8080
  │
  └─ bouton « tick » $fetch(apiUrl/…) → NUXT_PUBLIC_API_URL
                                       http://localhost:6602  (CORS *)
```

### Jeu (navigateur ↔ Caddy ↔ Godot)

```text
Client HTML5 (6605)
  └─ ws://localhost:6605/ws
       └─ Caddy reverse_proxy
            └─ godot:8999
                 ├─ submit_input(steer, throttle)   client → serveur (30 Hz)
                 └─ snapshot([...voitures])         serveur → clients (30 Hz)
```

Hors navigateur (éditeur / CLI) : connexion **directe** `ws://127.0.0.1:6604`.

---

## 9. Le jeu Godot en détail

### Les rôles Godot à ne pas confondre

| Chose | Quoi | URL ? |
|-------|------|-------|
| Éditeur natif | App bureau pour éditer scènes / scripts | `godot --path godot -e --language fr` |
| Éditeur noVNC | Conteneur `godot-editor` (profil `editor`) | http://localhost:6606/vnc.html |
| Serveur dédié | Conteneur `godot` headless | `ws://…:6604` (brut, pas HTTP) |
| Client HTML5 | Export Web servi par Caddy | http://localhost:6605 |

Ouvrir `http://localhost:6604` dans le navigateur **n’affiche rien** : ce n’est
pas un serveur HTTP.

### Un projet, deux rôles

[`godot/main.gd`](../godot/main.gd) décide :

- pas d’affichage (`DisplayServer` = headless) → **Server**
- sinon → **Client**
- forçage : `-- --server` ou `-- --client`

```text
main.tscn (Main)
├── Net       net.gd      TOUJOURS — RPC + boucle 30 Hz
├── Server    server.gd   si rôle serveur
└── Client    client.gd   si rôle client
```

### Règle d’or : chemin du nœud `Net`

Godot route les RPC par **chemin de nœud**. `Net` doit exister au même endroit
des deux côtés : `/root/Main/Net`.

Si vous déplacez ou renommez `Net` d’un seul côté, les RPC **échouent en silence**
(pas d’exception visible).

### Autorité serveur

- Client : lit clavier → `local_input` → RPC `submit_input`
- Serveur : `CarPhysics.step` sur chaque voiture → RPC `snapshot`
- Client : **interpole** les positions pour le rendu — **pas** de simulation
  locale (sauf si vous ajoutez réconciliation + prédiction)

Code partagé déterministe, sans état de partie :

- [`shared/car_physics.gd`](../godot/shared/car_physics.gd)
- [`shared/track.gd`](../godot/shared/track.gd) — anneau elliptique
- [`shared/car_state.gd`](../godot/shared/car_state.gd) — sérialisation wire

Tours : **angle polaire cumulé** autour du centre (pas de ligne d’arrivée) —
fonctionne dans les deux sens de rotation.

### Connexion navigateur et reconnexion

- URL par défaut web : `ws://<host:port_de_la_page>/ws` (même origine)
- `?port=6604` force le mode direct (diagnostic)
- Retry toutes les **3 s** avec un **nouveau** `WebSocketMultiplayerPeer`
- Signaux MultiplayerAPI branchés **une fois**, avant la première tentative

### Export Web

```bash
./godot/export-web.sh
```

Tourne **dans** le conteneur (templates). Recopie `web-extra/` (ex. `diag.html`),
corrige le propriétaire des fichiers, redémarre Caddy.

Preset actuel : variante **sans threads** (compatible partout). Les headers
COOP/COEP sont déjà envoyés si vous basculez `thread_support` plus tard.

---

## 10. API backend

Base : `http://localhost:6602`

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/healthz` | Liveness (Docker) |
| GET | `/api/health` | Postgres + pgvector + Redis |
| GET | `/api/telemetry` | Compteurs Redis |
| POST | `/api/telemetry/tick?driver=nom` | Incrémente un tick |
| GET | `/api/leaderboard` | Meilleurs tours (Postgres) |
| GET | `/api/similar?speed=&braking=&consistency=` | Similarité cosinus |

Exemples :

```bash
curl -s http://localhost:6602/api/health | jq
curl -s -X POST "http://localhost:6602/api/telemetry/tick?driver=alpha"
curl -s "http://localhost:6602/api/similar?speed=0.9&braking=0.8&consistency=0.6" | jq
```

`/api/similar` ordonne par distance cosinus (`<=>`) au vecteur de requête.

Générer `go.sum` sans Go sur l’hôte :

```bash
cd backend
docker run --rm -v "$PWD":/app -w /app golang:1.27.1-alpine go mod tidy
```

---

## 11. Frontend Nuxt

### Deux URL d’API (à ne jamais fusionner)

| Qui appelle | Variable | Valeur typique | Réseau |
|-------------|----------|----------------|--------|
| Nitro (SSR) | `NUXT_INTERNAL_API_URL` | `http://backend:8080` | DNS Docker |
| Navigateur | `NUXT_PUBLIC_API_URL` | `http://localhost:6602` | Port publié |

Config : [`frontend/nuxt.config.ts`](../frontend/nuxt.config.ts).

La route [`status.get.ts`](../frontend/server/api/status.get.ts) appelle en
parallèle health, telemetry, leaderboard, similar — pour le rendu initial de
`app.vue`.

Le bouton « Envoyer un tick » appelle **directement** le backend depuis le
navigateur : ça valide à la fois le port publié et le CORS.

### Pourquoi Node 24 ?

Sous Node 20/22 (npm 10), `npm install` peut planter :

```text
Cannot read properties of null (reading 'edgesOut')
```

Bug d’*arborist* ; Node 24 (npm 11) l’évite. Ne pas rétrograder l’image.

Rester sur **Nuxt 3** et **vue-router v4** (la v5 casse Nuxt 3).

---

## 12. Points d’attention (pièges)

Checklist des problèmes **déjà rencontrés** sur la mise en place de base.
Lisez-la avant de « simplifier » la config.

### Infrastructure

| Piège | Symptôme | Règle |
|-------|----------|--------|
| Pas de `.env` / variables manquantes | User/DB inattendus (`game_user`/`game_db`) | Toujours `cp .env.example .env` ; Compose a d’autres defaults |
| Ports 5432/6379/8080/3000 | `port is already allocated` | Garder 6600–6606 via `.env` |
| Volume PG sur `…/data` | Conteneur PG18 refuse de démarrer | Monter `/var/lib/postgresql` |
| `version: '3.8'` en tête Compose | Warning Compose v2 | Utiliser `name: projet-6tt` |
| Init SQL modifié + `restart` | Ancien schéma | `down -v` puis `up` |
| Volume sur share Godot | Copie 1.3 Go inutile | Ne pas monter `/root/.local/share/godot` |

### Godot / WebSocket

| Piège | Symptôme | Règle |
|-------|----------|--------|
| `--main-pack project.godot` | Échec démarrage | `--headless --path /project` |
| Connexion navigateur → `:6604` | « serveur injoignable », logs vides | Passer par `/ws` (même origine) |
| Ouvrir `/ws` en HTTP dans le navigateur | **426** Caddy | Normal ; le jeu ouvre un WebSocket depuis `index.html` |
| Cookies localhost trop gros | 502 Caddy après ~3 s | Garder `header_up -Cookie` etc. |
| Godot ne log pas les handshakes ratés | Journal serveur vide | Regarder `logs webclient` |
| Réutiliser un peer WS échoué | Plus jamais de reconnexion | Nouveau peer à chaque essai |
| Signaux branchés trop tard | Course au démarrage | Brancher avant `_try_connect` |
| Déplacer le nœud `Net` | RPC silencieux | Chemin `/root/Main/Net` |
| Oublier `export-web.sh` | Navigateur sur vieux build | Réexporter après chaque modif jeu |

### Frontend / Backend

| Piège | Symptôme | Règle |
|-------|----------|--------|
| Une seule URL API | SSR ou navigateur casse | Dual `INTERNAL` / `PUBLIC` |
| Node 20 pour le frontend | Crash npm `edgesOut` | Node 24 |
| Nuxt 4 / vue-router 5 | Build cassé | Nuxt 3 + router v4 |
| Save Go pendant compile Air | Rebuild manquant | Re-sauver le fichier |
| CORS trop strict en local | Tick bouton échoue | `CORS_ORIGIN=*` en dev |

### Diagnostic WebSocket (méthode)

1. Ouvrir http://localhost:6605/diag.html — verdict proxy vs direct.
2. `docker compose logs webclient` — y a-t-il des `/ws` ? des 502 ?
3. `docker compose logs godot` — y a-t-il des `[6TT] Pilote connecte` ?
4. `?port=6604` sur l’URL du jeu — si le direct marche et le proxy non → Caddy ;
   si les deux échouent → serveur Godot ou firewall navigateur.

---

## 13. Valider et diagnostiquer

```bash
docker compose ps
curl -s http://localhost:6602/api/health | jq      # "healthy"
curl -s http://localhost:6603/api/status | jq      # SSR → backend
curl -sI http://localhost:6605/                    # 200
docker compose logs --tail=20 godot                # lignes [6TT]
```

Boucle réseau sans navigateur :

```bash
godot --headless --path godot --quit-after 200 -- --client
# attendu : [6TT] premier instantane recu — N voiture(s) en piste
```

Remise à zéro complète (détruit les volumes) :

```bash
docker compose down -v
docker compose up -d --build
```

---

## 14. Graphify (graphe de code)

Le dépôt peut contenir un graphe local `graphify-out/` (outil **graphify**) pour
aider les agents et l’exploration de dépendances.

```bash
graphify . --code-only          # bootstrap AST (0 coût API)
graphify query "backend health"
graphify path "handleHealth" "handleTelemetry" --undirected
graphify update .               # après modification de code
```

**Limite importante :** les scripts **GDScript (`.gd`)** ne sont pas indexés en
AST par graphify. Pour le jeu, orientez-vous via ce guide / README / CLAUDE,
puis lisez les fichiers `.gd` directement.

Fichiers infra sans extension reconnue (`Caddyfile`, `Dockerfile`, souvent
ignorés en `--code-only`) : se référer à Compose et à ce guide.

---

## 15. Pistes de travail

Idées d’extensions cohérentes avec l’existant (à valider avec l’enseignant) :

1. Brancher le serveur Godot sur l’API (`BACKEND_URL`) pour pousser meilleurs tours.
2. Afficher le classement live sur le HUD du client.
3. Auth / salles de jeu (au-delà du peer id Godot).
4. Prédiction client + réconciliation (au lieu de la seule interpolation).
5. Variante export Web *avec threads* (headers déjà prêts dans Caddy).
6. Durcir pour un faux « staging » : CORS explicite, ports BDD fermés, build
   multi-stage Go + `nuxt build`.

---

## 16. Versions de référence

Lignes majeures / tags d’image du dépôt (les *patch* exacts évoluent au rebuild) :

| Composant | Ligne / tag | | Composant | Ligne / tag |
|-----------|-------------|--|-----------|-------------|
| PostgreSQL | **18** (`pg18`) | | Go | **1.27.1** |
| pgvector | **0.8.6** | | Air | 1.x (image backend) |
| Redis | **8.8**-alpine | | Node | **24** (npm 11) |
| Caddy | **2.11**-alpine | | Nuxt | **3.21.x** (`package.json`) |
| Godot | **4.7.2** | | Tailwind | 3.4.x |

- Vérifier le runtime : `docker compose exec postgres psql -c 'SELECT version();'` etc.
- **pgvector** : rester sur la dernière 0.8.x publiée (pas de downgrade inutile).
- **Nuxt 4** : migration volontairement non faite (`app/` + breaking changes).

---

*Document maintenu pour les élèves 6TT — à jour avec la configuration du dépôt
projet-6TT. En cas de divergence, le code et `docker-compose.yml` font foi.*

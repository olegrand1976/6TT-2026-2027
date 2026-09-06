# CLAUDE.md

Contexte pour agents IA (Cursor / Claude Code) sur ce dépôt.

- Documentation **humains / élèves** : [README.md](README.md) + **[docs/GUIDE-ELEVES.md](docs/GUIDE-ELEVES.md)**
- Ne pas inventer de ports, d’URL API ou de chemins Godot : la config ci-dessous
  et le guide élèves font foi.

## Ce qu'est le projet

Environnement de test conteneurisé pour un jeu de course 2D multijoueur. Six
services orchestrés par Docker Compose :

| Service     | Techno                          | Port hôte | Port interne |
|-------------|---------------------------------|-----------|--------------|
| `postgres`  | pgvector/pgvector:0.8.6-pg18    | 6600      | 5432         |
| `redis`     | redis:8.8-alpine                | 6601      | 6379         |
| `backend`   | Go 1.27.1 + Air                 | 6602      | 8080         |
| `frontend`  | Nuxt 3 + Tailwind (node 24)     | 6603      | 3000         |
| `godot`     | Godot 4.7.2 headless            | 6604      | 8999         |
| `webclient` | Caddy 2.11 (client HTML5)       | 6605      | 80           |

**Dev only** : hot-reload, CORS `*`, ports BDD exposés. Le jeu (WS) et l’API Go
ne sont **pas encore** branchés bout-en-bout (Godot loggue `BACKEND_URL` seulement).

## Graphify (obligatoire pour explorer)

Graphe local : `graphify-out/` (généré).

Avant Read / Grep / Glob d’exploration :

```bash
graphify query "<question>"
graphify path "<A>" "<B>"
graphify explain "<concept>"
```

Après modification de code : `graphify update .`

Si `graphify-out/graph.json` est absent : `graphify . --code-only` puis
`graphify cluster-only .` au besoin.

**Limite** : les `.gd` / `.tscn` ne sont **pas** indexés en AST. Pour le jeu :
orienter via docs / graphe (README, CLAUDE, export-web.sh, backend), puis lire
les `.gd` directement. Inclure cette règle dans tout prompt de subagent.

## Règles à respecter

**Ne pas revenir aux ports standards (5432/6379/8080/3000).** Occupés sur la
machine de labo. Ports hôte uniquement via `.env`. Ports internes inchangés.

**Toujours partir de `.env.example`.** Sans `.env` complet, Compose utilise
`game_user` / `game_db` / `game_password` — différents de l’example
(`game_admin` / `racing_game_db`). Les commandes doc suivent l’example.

**Deux URL d’API frontend — ne pas fusionner.**

- `NUXT_INTERNAL_API_URL` = `http://backend:8080` (SSR Nitro / DNS Docker)
- `NUXT_PUBLIC_API_URL` = `http://localhost:6602` (navigateur)

**Node 24 minimum** (npm 11). npm 10 plante : `edgesOut` null sur l’arbre Nuxt.

**Rester sur Nuxt 3** ; `vue-router` en v4 (la v5 casse Nuxt 3).

**Godot** : `--headless --path /project` (pas `--main-pack`). `ENTRYPOINT []`.

**Ne pas monter** de volume sur `/root/.local/share/godot` (templates ~1.3 Go
déjà dans l’image).

**Postgres 18** : volume sur `/var/lib/postgresql` (pas `…/data`).

## Le projet Godot

Un projet, deux rôles ([godot/main.gd](godot/main.gd)) : headless → Server,
sinon Client. Forçage : `-- --server` / `-- --client`.

```text
main.tscn (Main)
├── Net       net.gd — RPC + boucle 30 Hz   (TOUJOURS, chemin /root/Main/Net)
├── Server    server.gd
└── Client    client.gd
```

**`Net` doit rester à `/root/Main/Net` des deux côtés.** Écart = RPC silencieux.

Autorité serveur : `submit_input` → simule → `snapshot`. Client = interpolation
seulement. Physique / track partagés, sans état. Tours = angle polaire cumulé.

Après modif jeu : `./godot/export-web.sh` (export dans le conteneur).

**Navigateur** : WS via **même origine** `/ws` (Caddy → `godot:8999`), jamais
6604 par défaut.

Le relais Caddy retire `Cookie`, `User-Agent` et consorts (`header_up -…`) : le
serveur WS Godot coupe si le handshake dépasse ~4 Ko (cookies `localhost` des
autres services). Ne pas retirer ces directives.

Godot **ne journalise pas** les handshakes échoués : journal serveur vide ≠
trafic absent — vérifier `docker compose logs webclient` (502 après ~3 s).
Diagnostic : `?port=NNNN`, `/diag.html`.

**Reconnexion** toutes les 3 s avec un **nouveau** `WebSocketMultiplayerPeer`.
Signaux MultiplayerAPI branchés **une fois**, avant la première tentative.

## Points de structure

- `db/init/01-extensions.sql` : uniquement à la **création** du volume Postgres
  → rejouer avec `docker compose down -v && docker compose up -d`.
- Backend : un fichier `backend/main.go`, `net/http` Go 1.22+, `pgxpool`,
  `go-redis/v9`.
- Frontend : une route serveur `frontend/server/api/status.get.ts` (agrégat SSR).
- `go.sum` sans Go hôte :
  `docker run --rm -v "$PWD":/app -w /app golang:1.27.1-alpine go mod tidy`
  (depuis `backend/`).
- Éditeur hôte : `godot --path godot -e` (`~/.local/bin/godot`) — **sans**
  templates d’export.

## Vérifier que la stack tourne

```bash
docker compose ps
curl -s http://localhost:6602/api/health | jq
curl -s http://localhost:6603/api/status | jq
curl -sI http://localhost:6605/
docker compose logs --tail=5 godot
godot --headless --path godot --quit-after 200 -- --client
```

`godot` : pas de healthcheck HTTP — se fier aux logs `[6TT]`.

## Limite connue

Save d’un fichier Go **pendant** une compile Air : événement parfois ignoré →
réenregistrer le fichier.

## Doc élèves

Toute explication longue (flux, tableaux de pièges, pistes d’exercices) va dans
[docs/GUIDE-ELEVES.md](docs/GUIDE-ELEVES.md). Mettre à jour ce guide quand la
config réelle change (ports, versions, comportement réseau).

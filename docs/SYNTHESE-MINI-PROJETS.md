# Synthèse — mini-projets Rac6TT

Deux parcours dans **`exemples/`**, indépendants de la stack principale (**6600–6606**). Détail : [GUIDE-ELEVES.md](GUIDE-ELEVES.md) · [PRESENTATION-MINI-PROJETS.md](PRESENTATION-MINI-PROJETS.md).

## Godot — `exemples/godot/` (9 modules)

| # | Dossier | En bref |
|---|---------|---------|
| 01 | `01-valider-la-stack` | Script `verify.sh` — stack OK |
| 02 | `02-reseau-et-ports` | Carte des ports Docker |
| 03 | `03-donnees-postgres-redis` | SQL + Redis (lab stack) |
| 04 | `04-api-et-dashboard` | Nuxt ↔ API Go |
| **05** | **`05-mouvement-2d`** | **Godot : plateformes 2D** |
| 06 | `06-client-web-et-websocket` | Jeu HTML5 + `/ws` |
| 07 | `07-editeur-novnc` | Éditeur port 6606 |
| **08** | **`08-course-locale`** | **Godot : hot lap solo (physique piste)** |
| **09** | **`09-reseau-minimal`** | **Godot : WS + RPC (port 8970)** |

Ordre : **01→04 → 05→08→09 → 06→07**. Jeu final : dossier **`godot/`** à la racine.

## Go — `exemples/go/` (8 stacks, ports 6710–6718)

| # | Thème | Port |
|---|--------|------|
| 01 | HTTP minimal (Garage Zéro) | 6710 |
| 02 | API JSON (Podium Live) | 6711 |
| 03 | Postgres + pgx (pilotes) | 6712 |
| 04 | Redis compteur (Hype Train) | 6714 |
| 05 | Caddy static (Fan Zone) | 6715 |
| 06 | Caddy + API (Game Launcher) | 6716 |
| 07 | Vote piste (Redis hash) | 6717 |
| 08 | Mur paddock (Redis list) | 6718 |

Ordre : **01→04 → 07→08 → 05→06**. Chaque dossier : `docker compose up -d --build`.

## Démarrage rapide

```bash
# Labs Godot (stack racine)
cp -n .env.example .env && docker compose up -d --build
bash exemples/godot/01-valider-la-stack/verify.sh

# Un mini Go
cd exemples/go/01-hello-http && docker compose up -d --build
```

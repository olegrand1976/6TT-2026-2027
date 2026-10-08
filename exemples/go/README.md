# Parcours exemples Go — thèmes Rac6TT / ado

Mini-projets **autonomes** avec `docker-compose.yml`. Ports **6710–6718**
(pas de conflit avec la stack principale 6600–6606).

| # | Dossier | Thème ludique | Technique | Port |
|---|---------|---------------|-----------|------|
| 01 | [01-hello-http](01-hello-http/) | **Garage Zéro** — allumer le moteur | `net/http` | 6710 |
| 02 | [02-api-json](02-api-json/) | **Podium Live** — classement du soir | JSON / query | 6711 |
| 03 | [03-postgres-pgx](03-postgres-pgx/) | **Garage des pilotes** — équipes & couleurs | Postgres + pgx | 6712 |
| 04 | [04-redis-compteur](04-redis-compteur/) | **Hype Train** — compteur live | Redis INCR | 6714 |
| 05 | [05-caddy-static](05-caddy-static/) | **Fan Zone** — landing course | Caddy static | 6715 |
| 06 | [06-caddy-proxy-api](06-caddy-proxy-api/) | **Game Launcher** — bouton Jouer + API | Caddy proxy | 6716 |
| 07 | [07-vote-piste](07-vote-piste/) | **Vote de piste** — sondage map du soir | Redis hash | 6717 |
| 08 | [08-mur-paddock](08-mur-paddock/) | **Mur du paddock** — messages entre potes | Redis list | 6718 |

## Lancer un exemple

```bash
cd exemples/go/07-vote-piste
docker compose up -d --build
docker compose ps
docker compose down
```

## Ordre pédagogique

**01 → 02 → 03 → 04 → 07 → 08** (API & données), puis **05 → 06** (web + same-origin).

## Lien Rac6TT

Backend complet : [`backend/main.go`](../../backend/main.go).

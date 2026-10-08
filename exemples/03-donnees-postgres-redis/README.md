# 03 — Données Postgres et Redis

## Objectif

Manipuler **PostgreSQL + pgvector** et **Redis** tels qu’utilisés par l’API Go du dashboard.

## Prérequis

- Stack up, `.env` aligné sur `.env.example` (`game_admin` / `racing_game_db`)

## Durée

~30 minutes.

## Étapes

### Postgres (port hôte 6600)

1. Connexion (adapter user/db à votre `.env`) :
   ```bash
   source .env 2>/dev/null || true
   PGPASSWORD="${POSTGRES_PASSWORD:-change_me}" psql -h localhost -p "${POSTGRES_PORT:-6600}" \
     -U "${POSTGRES_USER:-game_admin}" -d "${POSTGRES_DB:-racing_game_db}"
   ```
2. Exécuter les requêtes du fichier [`requetes-pgvector.sql`](requetes-pgvector.sql).
3. Comparer avec l’API :
   ```bash
   curl -s "http://localhost:6602/api/similar?speed=0.9&braking=0.8&consistency=0.6" | jq
   ```

### Redis (port hôte 6601)

1. Lancer le lab ticks :
   ```bash
   bash exemples/03-donnees-postgres-redis/redis-ticks.sh
   ```
2. Vérifier sur http://localhost:6603 (compteurs télémétrie).

## Critères de réussite

- Extension `vector` listée dans `\dx`
- Table `telemetry_samples` contient les lignes seed
- `redis-ticks.sh` incrémente une clé visible côté API `/api/telemetry`

## Pièges

- Init SQL rejouée seulement à la **création** du volume : `docker compose down -v` si vous modifiez `db/init/`.

## Lien Rac6TT

[`db/init/01-extensions.sql`](../../db/init/01-extensions.sql) · [`backend/main.go`](../../backend/main.go) (handlers health / similar / telemetry).

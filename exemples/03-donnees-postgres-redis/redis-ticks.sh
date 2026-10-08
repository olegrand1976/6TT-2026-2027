#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
[[ -f .env ]] && set -a && source .env && set +a
REDIS_PORT="${REDIS_PORT:-6601}"
if ! command -v redis-cli >/dev/null 2>&1; then
  echo "redis-cli introuvable — installez redis-tools ou utilisez le conteneur :" >&2
  echo "  docker compose exec redis redis-cli INCR 6tt:lab:ticks" >&2
  exit 1
fi
KEY="6tt:lab:ticks"
VAL="$(redis-cli -p "$REDIS_PORT" INCR "$KEY")"
echo "INCR $KEY → $VAL"
echo "Vérifiez http://localhost:${FRONTEND_PORT:-6603} ou curl http://localhost:${BACKEND_PORT:-6602}/api/telemetry"

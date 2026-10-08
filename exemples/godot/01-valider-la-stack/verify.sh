#!/usr/bin/env bash
# Valide la stack Rac6TT (guide §4 et §13). Codes de sortie : 0 = OK, 1 = échec.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a && source .env && set +a
fi

BACKEND_PORT="${BACKEND_PORT:-6602}"
FRONTEND_PORT="${FRONTEND_PORT:-6603}"
WEBCLIENT_PORT="${WEBCLIENT_PORT:-6605}"

fail=0
ok() { echo "  OK  $*"; }
ko() { echo "  KO  $*"; fail=1; }

echo "[01] Conteneurs"
if docker compose ps --format '{{.Service}} {{.Status}}' 2>/dev/null | grep -q healthy; then
  ok "docker compose ps (au moins un healthy)"
else
  ko "docker compose ps — lancez: docker compose up -d --build"
fi

echo "[01] Backend /api/health"
if curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/health" | grep -q '"healthy"'; then
  ok "http://localhost:${BACKEND_PORT}/api/health"
else
  ko "backend unhealthy ou injoignable sur ${BACKEND_PORT}"
fi

echo "[01] Frontend SSR /api/status"
if curl -sf "http://127.0.0.1:${FRONTEND_PORT}/api/status" | grep -q 'health'; then
  ok "http://localhost:${FRONTEND_PORT}/api/status"
else
  ko "frontend SSR status"
fi

echo "[01] Client web"
code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${WEBCLIENT_PORT}/")"
if [[ "$code" == "200" ]]; then
  ok "http://localhost:${WEBCLIENT_PORT}/ (${code})"
else
  ko "webclient HTTP ${code}"
fi

echo "[01] Godot (logs récents)"
if docker compose logs --tail=5 godot 2>/dev/null | grep -q '\[6TT\]'; then
  ok "logs godot contiennent [6TT]"
else
  ko "pas de trace [6TT] dans docker compose logs godot"
fi

if [[ "$fail" -eq 0 ]]; then
  echo ""
  echo "Stack validée. Étape manuelle : ouvrir http://localhost:${WEBCLIENT_PORT} (2 onglets) et http://localhost:${FRONTEND_PORT}"
  exit 0
fi
echo ""
echo "Échec — voir docs/GUIDE-ELEVES.md §12 et §13"
exit 1

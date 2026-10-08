#!/usr/bin/env bash
# Re-indexe les fichiers montes depuis l'hote avant le serveur WS.
set -euo pipefail

echo "[6TT] Import rapide (serveur headless)..."
godot --headless --path /project --import >/dev/null 2>&1 || true

exec "$@"

#!/usr/bin/env bash
# Exporte le client en HTML5 et recharge le service qui le sert.
#
# L'export tourne dans le conteneur : c'est lui qui embarque les templates
# d'export Godot (~1.3 Go), inutiles a installer sur l'hote.
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p godot/build/web

docker compose run --rm --no-deps \
  -e "HOST_UID=$(id -u)" -e "HOST_GID=$(id -g)" \
  godot /usr/local/bin/prepare-stack.sh --force-export

docker compose up -d webclient >/dev/null
docker compose restart webclient >/dev/null

port="$(grep -E '^WEBCLIENT_PORT=' .env 2>/dev/null | cut -d= -f2 || echo 6605)"
echo "Client web disponible sur http://localhost:${port:-6605}"

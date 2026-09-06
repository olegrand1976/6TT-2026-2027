#!/usr/bin/env bash
# Exporte le client en HTML5 et recharge le service qui le sert.
#
# L'export tourne dans le conteneur : c'est lui qui embarque les templates
# d'export Godot (~1.3 Go), inutiles a installer sur l'hote.
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p godot/build/web

docker compose run --rm --no-deps godot sh -c '
  godot --headless --path /project --import >/dev/null 2>&1
  godot --headless --path /project --export-release Web /project/build/web/index.html
'

# Pages annexes non generees par Godot (diagnostic...), recopiees a chaque
# export car l'export ecrase le repertoire.
cp -f godot/web-extra/* godot/build/web/ 2>/dev/null || true

# L'export tourne en root dans le conteneur : on rend les fichiers a l'hote.
docker run --rm -v "$PWD/godot:/g" alpine \
  sh -c 'chown -R '"$(id -u):$(id -g)"' /g/build /g/.godot 2>/dev/null || true'

docker compose up -d webclient >/dev/null
docker compose restart webclient >/dev/null

port="$(grep -E '^WEBCLIENT_PORT=' .env 2>/dev/null | cut -d= -f2 || echo 6605)"
echo "Client web disponible sur http://localhost:${port:-6605}"

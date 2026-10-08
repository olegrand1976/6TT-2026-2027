#!/usr/bin/env bash
# Import Godot + export web si absent (premier clone). Utilise par godot-prepare
# au `docker compose up` et par export-web.sh avec --force-export.
set -euo pipefail

FORCE_EXPORT=0
for arg in "$@"; do
	case "$arg" in
	--force-export) FORCE_EXPORT=1 ;;
	esac
done

cd /project
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"

need_import=0
need_export=0

if [ ! -d .godot ] || [ ! -f .godot/global_script_class_cache.cfg ]; then
	need_import=1
fi
if [ ! -f build/web/index.html ] || [ "$FORCE_EXPORT" -eq 1 ]; then
	need_export=1
	need_import=1
fi

if [ "$need_import" -eq 0 ] && [ "$need_export" -eq 0 ]; then
	echo "[6TT] Projet deja importe et client web present — rien a faire."
	exit 0
fi

echo "[6TT] Import Godot (classes globales, textures)..."
godot --headless --path /project --import

if [ "$need_export" -eq 1 ]; then
	echo "[6TT] Export client HTML5..."
	mkdir -p build/web
	godot --headless --path /project --export-release Web /project/build/web/index.html
	cp -f web-extra/* build/web/ 2>/dev/null || true
fi

chown -R "${HOST_UID}:${HOST_GID}" /project/build /project/.godot 2>/dev/null || true
echo "[6TT] Prepare Godot termine."

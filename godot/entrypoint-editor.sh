#!/usr/bin/env bash
# Editeur Godot dans le conteneur : Xvfb + noVNC (dev local uniquement, VNC sans mot de passe).
set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_PORT="${VNC_PORT:-5900}"

X_DISPLAY_NUM="${DISPLAY#*:}"
X_SOCKET="/tmp/.X11-unix/X${X_DISPLAY_NUM}"

Xvfb "${DISPLAY}" -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
for _ in $(seq 1 60); do
	if [ -S "${X_SOCKET}" ]; then
		break
	fi
	sleep 0.25
done
if [ ! -S "${X_SOCKET}" ]; then
	echo "[6TT] Echec demarrage Xvfb sur ${DISPLAY}" >&2
	exit 1
fi

dbus-daemon --session --fork 2>/dev/null || true
fluxbox &
x11vnc -display "${DISPLAY}" -forever -shared -rfbport "${VNC_PORT}" -nopw &
websockify --web=/usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" &

echo "[6TT] Editeur Godot — noVNC sur le port ${NOVNC_PORT} (vnc.html)"
exec godot --path /project -e --display-driver x11 --rendering-driver opengl3

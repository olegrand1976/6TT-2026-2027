#!/usr/bin/env bash
# Editeur Godot dans le conteneur : Xvfb + noVNC (dev local uniquement, VNC sans mot de passe).
# Projet et prefs editeur : volumes montes sur /project et /editor-home (persistants sur l'hote).
set -euo pipefail

export DISPLAY="${DISPLAY:-:99}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_PORT="${VNC_PORT:-5900}"
EDITOR_SCREEN="${EDITOR_SCREEN:-1920x1080x24}"
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
export HOME="${EDITOR_HOME:-/editor-home}"

fix_project_ownership() {
	# Fichiers crees en root dans le conteneur : rendre l'ecriture a l'utilisateur hote.
	chown -R "${HOST_UID}:${HOST_GID}" /project "${HOME}" 2>/dev/null || true
}

cleanup() {
	fix_project_ownership
	kill "${XVFB_PID:-}" 2>/dev/null || true
	pkill -x x11vnc 2>/dev/null || true
	pkill -f websockify 2>/dev/null || true
}

mkdir -p "${HOME}/.config/godot"
fix_project_ownership
trap cleanup EXIT

X_DISPLAY_NUM="${DISPLAY#*:}"
X_SOCKET="/tmp/.X11-unix/X${X_DISPLAY_NUM}"
X_LOCK="/tmp/.X${X_DISPLAY_NUM}-lock"

# Redemarrage Docker (restart policy) : nettoyer lock/socket X11 orphelins.
pkill -x Xvfb 2>/dev/null || true
rm -f "${X_LOCK}" 2>/dev/null || true
rm -f "${X_SOCKET}" 2>/dev/null || true

Xvfb "${DISPLAY}" -screen 0 "${EDITOR_SCREEN}" -ac +extension GLX +render -noreset &
XVFB_PID=$!
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
# Clavier AZERTY + verrou numerique explicite (sinon noVNC / l'hote divergent souvent).
setxkbmap fr 2>/dev/null || setxkbmap us
EDITOR_NUMLOCK="${EDITOR_NUMLOCK:-on}"
case "${EDITOR_NUMLOCK}" in
	on | off) numlockx "${EDITOR_NUMLOCK}" ;;
	toggle) numlockx toggle ;;
	*) numlockx on ;;
esac
sync_numlock() {
	numlockx "${EDITOR_NUMLOCK}" 2>/dev/null || true
}

sync_numlock
# Ne pas utiliser x11vnc -R clear_all : cela force Num Lock OFF a chaque connexion.
x11vnc -display "${DISPLAY}" -forever -shared -rfbport "${VNC_PORT}" -nopw \
	-modtweak -xkb -clear_mods \
	-accept "sh -c 'DISPLAY=${DISPLAY} numlockx ${EDITOR_NUMLOCK} 2>/dev/null || true; exit 0'" &
websockify --web=/usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" &

echo "[6TT] Scan des fichiers ajoutes sur l'hote (import)..."
gosu "${HOST_UID}:${HOST_GID}" godot --headless --path /project --import >/dev/null 2>&1 || true
fix_project_ownership

echo "[6TT] Editeur Godot (fr) — sauvegardes dans ./godot sur l'hote ; noVNC : vnc.html?autoconnect=true&resize=scale"
(
	sleep 5
	sync_numlock
) &
exec gosu "${HOST_UID}:${HOST_GID}" godot --path /project -e \
	--language fr \
	--display-driver x11 \
	--rendering-driver opengl3 \
	--rendering-method gl_compatibility \
	--fullscreen

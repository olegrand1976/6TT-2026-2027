# 06 — Client web et WebSocket

## Objectif

Comprendre **export HTML5**, le rôle de **`godot-prepare`**, le proxy Caddy `/ws` et le diagnostic réseau.

## Prérequis

- Stack up · module [02](../02-reseau-et-ports/) utile

## Durée

~30 minutes.

## Étapes

1. Schéma [`../_assets/flux-jeu-ws.svg`](../../_assets/flux-jeu-ws.svg).
2. Vérifier le build servi :
   ```bash
   ls -la godot/build/web/index.html
   curl -sI http://localhost:6605/ | head -5
   ```
3. Ouvrir http://localhost:6605/diag.html — noter le verdict **proxy** vs **direct**.
4. **Forcer un nouvel export** (après modif scène dans `godot/`) :
   ```bash
   ./godot/export-web.sh
   ```
5. Logs pendant une partie :
   ```bash
   docker compose logs --tail=30 webclient
   docker compose logs --tail=30 godot
   ```
6. Test **426** : ouvrir http://localhost:6605/ws dans le navigateur (HTTP simple) — réponse normale, pas un bug Godot.

## Critères de réussite

- Vous expliquez pourquoi le client web ne se connecte **pas** à `:6604` par défaut.
- `diag.html` confirme le chemin `/ws` OK avec la stack Docker.

## Pièges

| Symptôme | Piste |
|----------|--------|
| 502 sur `/ws` après ~3 s | Handshake trop lourd (cookies) — ne pas retirer `header_up -Cookie` du Caddyfile |
| Logs Godot vides | Handshakes ratés non loggés — regarder webclient |
| Vieux client | Oublier `export-web.sh` après modif jeu |

## Lien Rac6TT

[`godot/export-web.sh`](../../../godot/export-web.sh) · [`godot/Caddyfile`](../../../godot/Caddyfile) · [`godot/prepare-stack.sh`](../../../godot/prepare-stack.sh) · [GUIDE §9](../../../docs/GUIDE-ELEVES.md#9-le-jeu-godot-en-détail).

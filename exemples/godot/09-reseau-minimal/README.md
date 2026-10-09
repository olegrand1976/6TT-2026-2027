# 09 — Godot réseau minimal

## Objectif

Comprendre **WebSocketMultiplayerPeer**, le nœud **`Net` au même chemin**, RPC client → serveur → broadcast, avant d’ouvrir [`godot/scripts/network/net.gd`](../../../godot/scripts/network/net.gd).

## Prérequis

- Module [08](../08-course-locale/) · stack Rac6TT **non requise** (port **8970** dédié)

## Durée

~45 minutes.

## Étapes

1. **Serveur Docker** (recommandé) :
   ```bash
   cd exemples/godot/09-reseau-minimal
   docker compose up -d server
   ```
   Ou en local : `godot --headless --path . -- --server`
2. **Terminal B — client** (ou F5 dans l’éditeur) :
   ```bash
   godot --path exemples/godot/09-reseau-minimal -- --client
   ```
3. Lancer un **second client** (autre fenêtre `--client`) : deux cercles orange + le vôtre bleu.
4. Déplacer avec les **flèches** — le serveur agrège et renvoie `sync_state`.
5. Lire [`net.gd`](net.gd) et comparer au schéma [`../_assets/autorite-serveur.svg`](../../_assets/autorite-serveur.svg).

## Critères de réussite

- `[ex09] Client connecte` côté serveur.
- Déplacer le nœud `Net` dans l’éditeur casse les RPC — vous comprenez pourquoi Rac6TT impose `/root/Main/Net`.

## Pièges

- Port 8970 déjà pris → changer `Net.PORT` dans `net.gd` (les deux instances).
- Ne pas confondre avec le serveur Docker sur **6604** / **8999**.

## Lien Rac6TT

[`godot/scripts/main.gd`](../../../godot/scripts/main.gd) · [`godot/scripts/network/net.gd`](../../../godot/scripts/network/net.gd) · [`godot/scripts/server/server.gd`](../../../godot/scripts/server/server.gd) · [`godot/scripts/client/client.gd`](../../../godot/scripts/client/client.gd).

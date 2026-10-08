# 08 — Godot course locale

## Objectif

Piloter une voiture sur la **piste elliptique** Rac6TT en local : `Track`, `CarState`, `CarPhysics`, compteur de tours — **sans réseau**.

## Prérequis

- Module [05](../05-godot-mouvement-2d/) recommandé

## Durée

~45 minutes.

## Étapes

1. ```bash
   godot --path exemples/08-godot-course-locale -e --language fr
   ```
2. **F5** — flèches haut/bas = gaz/frein, gauche/droite = direction.
3. Comparer avec le schéma [`../_assets/autorite-serveur.svg`](../_assets/autorite-serveur.svg) : ici **vous** simulez (pas encore le serveur).
4. Lire [`shared/car_physics.gd`](shared/car_physics.gd) et le fichier équivalent Rac6TT [`godot/shared/car_physics.gd`](../../godot/shared/car_physics.gd).

## Critères de réussite

- Le compteur **Tour** augmente après un loop complet (angle polaire cumulé).
- Hors bitume : la voiture ralentit (`OFFTRACK_DRAG`).

## Pièges

- Tours négatifs si vous tournez en sens inverse — normal avec la logique polaire.

## Lien Rac6TT

Même géométrie que [`godot/shared/track.gd`](../../godot/shared/track.gd) · simulation serveur dans [`godot/net.gd`](../../godot/net.gd).

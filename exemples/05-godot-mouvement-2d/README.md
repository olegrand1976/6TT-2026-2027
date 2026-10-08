# 05 — Godot mouvement 2D

## Objectif

Pratiquer **CharacterBody2D**, gravité, sauts et plateformes avant la course Rac6TT.

## Prérequis

- Godot 4.7.2 installé ([guide §3](../../docs/GUIDE-ELEVES.md#3-démarrage))

## Durée

~45 minutes.

## Étapes

1. Ouvrir le projet :
   ```bash
   godot --path exemples/05-godot-mouvement-2d -e --language fr
   ```
2. Lancer **F5** — flèches + **Espace** (ui_accept) pour sauter.
3. Lire [`scripts/joueur.gd`](scripts/joueur.gd) et modifier `speed` / `jump_velocity`.
4. Dupliquer la plateforme dans `scenes/niveau.tscn` pour un petit parcours.

## Critères de réussite

- Le personnage (`assets/personne.svg`) reste sur la plateforme verte.
- Vous comprenez la différence `move_and_slide()` vs déplacement direct.

## Pièges

- Première ouverture : Godot importe les SVG (`.import` généré localement, non versionné).

## Lien Rac6TT

Physique arcade multijoueur : [`godot/shared/car_physics.gd`](../../godot/shared/car_physics.gd) (autorité serveur, pas de gravité).

Ce module remplace l’ancien dossier `godot/scenes_tests_exemples/`.

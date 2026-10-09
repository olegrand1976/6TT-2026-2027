# Jeu Rac6TT (Godot 4.7)

Architecture **modulaire** : piste = éléments fin, voiture = pièces + Resource de caractéristiques.

## Arborescence

```text
scenes/client/world/
├── world.tscn
├── track/
│   ├── track.tscn                    # assemble les calques
│   └── elements/
│       ├── grass · asphalt · dirt · curbs · start_line   # rendu actuel
│       ├── walls_layer + wall_segment                      # murs (à placer)
│       ├── decorations_layer + tree · rock                 # décor (à placer)
│       └── … (dupliquer un .tscn pour un nouveau matériau)
└── car/
    ├── cars_layer.tscn
    ├── car_view.tscn                 # specs + Parts/*
    └── parts/ body · nose · wheels · local_ring

resources/cars/default_car.tres       # CarSpecs (dimensions + gameplay ref.)
assets/track/ · assets/car/           # PNG (remplaçables dans l’éditeur)
scripts/shared/
├── track.gd                          # géométrie + palette (serveur & client)
└── car_specs.gd                      # profil voiture (Resource)
```

## Piste — éléments fin

| Scène | Rôle | z_index |
|-------|------|---------|
| `grass` | Fond herbe | -30 |
| `asphalt` | Ellipse bitume | -25 |
| `dirt` | Intérieur anneau (terre) | -24 |
| `curbs` | Bordures | -22 |
| `start_line` | Ligne de départ | -21 |
| `walls_layer` | Conteneur murs | -20 |
| `decorations_layer` | Arbres, cailloux… | -18 |

Chaque élément a une **texture** (`assets/track/…`) visible sur un `Sprite2D` / `Polygon2D` / `Line2D` dans la scène. `TrackElement` : `surface_texture` + `use_track_default` pour teinter ou remplacer l’image.

**Géométrie partagée** : `Track.OUTER` / `INNER` dans `scripts/shared/track.gd` (collisions serveur inchangées).

## Voiture — pièces & caractéristiques

| Pièce | Données lues dans `CarSpecs` |
|-------|------------------------------|
| `body` | `body_length`, `body_width` |
| `nose` | + `nose_lighten` |
| `wheels` | `wheel_radius`, offsets |
| `local_ring` | anneau joueur local |

Dupliquer `resources/cars/default_car.tres` → `sport.tres`, assigner sur une variante de `car_view.tscn`.

## Verdict architecture (revue)

| Critère | État |
|---------|------|
| Personnalisation visuelle par l’éditeur | OK — une scène = un matériau / une pièce |
| Cohérence serveur (autorité physique) | OK — `CarPhysics` + `Track.is_on_asphalt` restent la source de vérité |
| Évolution profils voiture côté serveur | **Prêt** — `CarPhysics.step(..., specs)` ; brancher un `CarSpecs` par pilote dans `net.gd` |
| Collisions murs / décor | **À brancher** — `walls_layer` / props sans impact physique pour l’instant |
| Pédagogie | OK — profondeur progressive (remplacer un `.tscn` avant de toucher au réseau) |

**Limite assumée** : ne pas dupliquer la logique physique dans chaque pièce ; un futur `CarProfile` serveur pourra réutiliser la même Resource ou un `.tres` miroir.

## Collisions (serveur)

- Autorité : `TrackCollision.resolve_tick()` après chaque pas `CarPhysics.step()` dans `net.gd`.
- **Voiture ↔ voiture** : cercles (`CAR_RADIUS`).
- **Voiture ↔ décor** : marqueurs `TrackCollisionMarker` sur `tree`, `rock`, `wall_segment` (enfant `Collision/`).
- Déplacer un arbre dans `track.tscn` met à jour la collision au prochain démarrage serveur (re-scan de la scène instanciée dans l’arbre Godot).
- Les positions des marqueurs utilisent `global_transform` : ne pas collecter les obstacles hors SceneTree.
- Bitume / herbe : toujours `Track.is_on_asphalt()` + rebords elliptiques (`CarPhysics.enforce_track_bounds`).

Règle RPC : **`Net` = `/root/Main/Net`**.

Doc : [docs/GUIDE-ELEVES.md](../docs/GUIDE-ELEVES.md) §9.

## Éditeur (Godot 4.7)

- Scène principale : `res://scenes/main.tscn` (alias racine `res://main.tscn` pour compat).
- Code source : `res://scripts/…` (les fichiers à la racine `main.gd`, `net.gd`, `client/`, `server/` ne sont que des **alias** pour l’éditeur).
- Fermer puis rouvrir un onglet si le LSP affiche encore d’anciennes lignes `preload("res://net.gd")`.
- Si le LSP affiche encore d’anciennes erreurs : **Projet → Recharger le projet courant** ou supprimer le cache local `.godot/` puis rouvrir (réimport ~1 min).

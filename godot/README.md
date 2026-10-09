# Jeu Rac6TT (Godot 4.7)

**Principe pédagogique** : ouvrir les **scènes** dans l’éditeur (nœuds, textures, exports). Les **scripts** restent pour le réseau, la physique et le minimum de glue visuelle.

## Voir le circuit dans l’éditeur

| Scène | Contenu |
|-------|---------|
| `scenes/network/net.tscn` | **Réseau seulement** (nœud `Net`) — viewport **vide**, normal. |
| `scenes/client/world/track/track.tscn` | **Circuit complet** (herbe, bitume, kerbs, murs, décor). |
| `scenes/client/world/world.tscn` | Piste + couche voitures + caméra. |
| `scenes/main.tscn` | Point d’entrée jeu (**F5**). |

Les éléments piste utilisent `track_element.gd` avec `@tool` : le rendu se met à jour dans l’éditeur dès l’ouverture de `track.tscn`.

**Caméra** : `FollowCamera` calcule le zoom pour cadrer `Track.OUTER` (`auto_fit_track`, `fit_padding`) ; recalcul si la fenêtre est redimensionnée.

## Arborescence

```text
scenes/
├── main.tscn · client/client.tscn · server/server.tscn · network/net.tscn
└── client/world/
    ├── world.tscn              # Track + CarsLayer + FollowCamera (sans script)
    ├── track/track.tscn      # assemble les éléments (sans script)
    ├── track/elements/       # une scène = un matériau / prop
    └── car/
        ├── car_view.tscn     # un script : specs + couleurs réseau
        ├── cars_layer.tscn
        └── parts/*.tscn      # Sprite2D uniquement (pas de script)

scripts/
├── main.gd · network/net.gd · client/client.gd · server/
├── client/world/
│   ├── track/track_element.gd   # seul script piste (kind + nœuds enfants)
│   └── car/car_view.gd
└── shared/                   # Track, CarPhysics, collisions serveur…
```

## Piste — scènes + `TrackElement`

Chaque `elements/*.tscn` référence **`track_element.gd`** avec un **`kind`** différent :

| Scène | `kind` (inspecteur) | Nœuds visibles |
|-------|---------------------|----------------|
| `grass` | GRASS | (dessin sur le nœud racine) |
| `asphalt` / `dirt` | ELLIPSE_SURFACE | `Polygon2D` + `ellipse_kind` + `ellipse_radii` |
| `curbs` | CURBS | `OuterKerb` / `InnerKerb` (Line2D) |
| `wall_edges` | WALL_EDGES | `OuterWall` / `InnerWall` (Line2D) |
| `start_line` | START_LINE | `Sprite2D` |
| `tree` / `rock` | SPRITE_DECOR | `Sprite2D` + `Collision/` |
| `wall_segment` | WALL_SEGMENT | `Sprite2D` + `length` / `thickness` |

`render_layer` = `z_index`. Textures : `@export surface_texture` ou PNG par défaut.

Conteneurs **`walls_layer`** / **`decorations_layer`** : simples `Node2D` (`z_index` dans la scène), pas de script.

## Voiture

- **`car_view.tscn`** : `CarSpecs` + arbre `Parts/` (body, nose, wheels, local_ring).
- **`car_view.gd`** : seul script voiture côté client (échelle / couleur depuis `CarSpecs` + réseau).
- Dupliquer `resources/cars/default_car.tres` pour un autre profil.

## Logique obligatoire (non déplaçable en scène seule)

| Script | Rôle |
|--------|------|
| `net.gd` | RPC, ticks 30 Hz |
| `client.gd` | WebSocket, lissage, HUD |
| `server.gd` | cycle de vie pilotes |
| `track.gd` · `car_physics.gd` | géométrie & autorité serveur |
| `track_collision*.gd` | obstacles depuis les scènes piste |

Règle RPC : **`Net` = `/root/Main/Net`**.

Doc élèves : [docs/GUIDE-ELEVES.md](../docs/GUIDE-ELEVES.md) §9 · lecture du code : [docs/CODE-GODOT.md](../docs/CODE-GODOT.md).

**Plan / dette / prochain commit** : [Plan de travail](../docs/CODE-GODOT.md#plan-de-travail-maintainers--suite-du-cours) dans `CODE-GODOT.md` (refactor non commité, `CarSpecs` serveur, kerbs, LSP).

# Lire le code Godot (projet-6TT)

Ce document complète [GUIDE-ELEVES.md](GUIDE-ELEVES.md) : **où est quoi**, **dans quel ordre ça s’exécute**, et **quels fichiers modifier** pour un exercice.

## Principe pédagogique

| Couche | Où | Comment |
|--------|-----|--------|
| **Visuel** | `scenes/` | Ouvrir l’éditeur : nœuds, textures, `@export` |
| **Glue légère** | `scripts/client/world/` | Peu de scripts (`track_element`, `car_view`, `cars_layer`) |
| **Réseau + physique** | `scripts/network/`, `scripts/shared/` | Autorité serveur, ne pas dupliquer côté client |
| **Serveur dédié** | `scripts/server/` | WebSocket + cycle de vie des pilotes |

**Règle d’or RPC** : le nœud `Net` doit être exactement à `/root/Main/Net` sur le client **et** sur le serveur.

## Arbre au runtime

```text
/root/Main                          scenes/main.tscn
├── Net                             scripts/network/net.gd  (30 Hz, RPC)
├── Server  (headless)              scripts/server/server.gd
└── Client  (jeu)                   scenes/client/client.tscn
    ├── World                       scenes/client/world/world.tscn
    │   ├── Track                   track.tscn → elements/*.tscn
    │   ├── CarsLayer               cars_layer.gd → car_view.tscn × N
    │   └── FollowCamera            follow_camera.gd
    └── HUD                         hud.gd
```

## Boucle réseau (30 images/s)

1. **Client** (`client.gd`) : lit le clavier → `_net.local_input`.
2. **Client** (`net.gd`, `_client_tick`) : RPC `submit_input` vers le serveur.
3. **Serveur** (`net.gd`, `_server_tick`) :
   - `CarPhysics.step` pour chaque voiture ;
   - `TrackCollision.resolve_tick` (voitures + obstacles) ;
   - RPC `snapshot` vers tous les clients.
4. **Client** (`net.gd`, `snapshot`) : met à jour `remote_cars`.
5. **Client** (`client.gd`) : lisse les positions pour l’affichage.
6. **Client** (`cars_layer.gd`) : déplace les `Rac6ttCarView`.

Le client **n’appelle pas** `CarPhysics.step` pour la voiture locale : il **affiche** ce que le serveur envoie.

## Fichiers `shared/` (serveur + client)

| Fichier | Rôle |
|---------|------|
| `track.gd` | Ellipses OUTER/INNER, spawn, `is_on_asphalt`, points pour le rendu |
| `car_physics.gd` | Accélération, grip, rebords — **serveur uniquement** |
| `car_state.gd` | Position, vitesse, tours ; sérialisation `to_wire` / `from_wire` |
| `car_specs.gd` | Resource `.tres` (dimensions + gameplay) |
| `track_collision.gd` | Scan des marqueurs dans `track.tscn`, poussées arcade |
| `track_collision_marker.gd` | Nœud à placer sous arbre / mur / rocher |
| `track_obstacle.gd` | Donnée collision (cercle ou segment) |

## Piste côté client

- Une scène par matériau : `scenes/client/world/track/elements/*.tscn`.
- **Un seul script** : `track_element.gd`, avec `@export var kind` (herbe, ellipse, bordures, etc.).
- Les **collisions** viennent des enfants `Collision/` (`collision_marker.tscn`), lus par le serveur au démarrage.

## Voiture côté client

- `car_view.tscn` : arbre `Parts/` (sprites sans script).
- `car_view.gd` : échelle / couleur depuis `CarSpecs` + `CarState.color_for(peer_id)`.
- `cars_layer.gd` : crée / détruit une vue par `peer_id` présent dans `remote_cars`.

## Exercices typiques

1. **Changer l’apparence** : textures dans `assets/`, ou `surface_texture` sur un élément de piste.
2. **Ajouter un arbre** : dupliquer `tree.tscn` dans `decorations_layer.tscn`, déplacer ; le serveur rescane au prochain démarrage.
3. **Nouveau profil voiture** : dupliquer `default_car.tres`, assigner sur `car_view.tscn`.
4. **Gameplay** : modifier `car_physics.gd` ou brancher `CarSpecs` dans `net.gd` → `_server_tick`.

## Backend Go / frontend Nuxt

Le jeu multijoueur **temps réel** passe par Godot (WebSocket). Le backend (`backend/main.go`) expose santé Postgres/Redis et des exemples API — pas encore branché au flux de course Godot. Voir [GUIDE-ELEVES.md](GUIDE-ELEVES.md) pour les ports.

## Dépannage éditeur / LSP (anciens chemins `elements/*.gd`)

Après la fusion vers **`track_element.gd`**, le language server peut encore afficher :

- `File not found` sur `res://scripts/client/world/track/elements/grass.gd` (etc.) ;
- `scale_factor` / `length` / `thickness` « already exists in parent class TrackElement ».

**Cause** : cache Godot (`.godot/editor/`) ou onglets ouverts sur d’**anciens** scripts qui faisaient `extends TrackElement` **et** redéclaraient les mêmes `@export`.

**État actuel du dépôt** : les `.tscn` pointent tous vers `track_element.gd` ; les fichiers `elements/*.gd` **n’existent plus** — ces erreurs ne reflètent **pas** le code des scènes, seulement un cache périmé.

**Correctif (dans l’ordre)** :

1. Fermer les onglets des anciens `elements/*.gd` dans l’éditeur.
2. **Projet → Recharger le projet courant** (ou redémarrer Godot).
3. Régénérer l’index :

   ```bash
   godot --headless --path godot --import --quit
   ```

   (équivalent Docker : voir `prepare-stack.sh` / conteneur `godot-prepare`.)

4. Si besoin : quitter Godot, supprimer `godot/.godot/` (re-import au prochain lancement — plus long).

Ne **pas** recréer les anciens `grass.gd` / `tree.gd` avec des `@export` dupliqués : c’était la source du parse error « member already exists ».

### F5 / debug : le jeu ne démarre pas (écran noir, erreurs `Net`)

**Cause la plus fréquente** : lancer une **sous-scène** (`client.tscn`, `follow_camera.tscn`, un `elements/*.tscn`) avec **F6** (*Exécuter la scène actuelle*) ou le bouton play sur la scène ouverte. Le client exige **`/root/Main/Net`** (RPC multijoueur) ; seule **`scenes/main.tscn`** instancie `Main` + `Net` + client.

**Correctif** :

1. Ouvrir `scenes/main.tscn`.
2. **F5** (*Exécuter le projet*) — pas F6 sur une sous-scène.
3. Vérifier la scène principale : *Projet → Paramètres du projet → Application → Scène principale* = `res://scenes/main.tscn`.
4. Serveur WS : stack Docker (`godot` sur **6604** hôte) ou `GAME_WS_URL` dans l’éditeur noVNC (`ws://godot:8999`).
5. **Vue jeu intégrée** (Godot 4.7) : si rien n’apparaît, basculer la vue jeu en **fenêtre séparée** (icône play / onglet *Jeu*) ou agrandir le panneau *Jeu* sous l’éditeur.

Message attendu si mauvaise scène : `[6TT] Net introuvable à /root/Main/Net`.

## Plan de travail (maintainers / suite du cours)

Ordre recommandé : **valider le refactor → commit → dettes gameplay / visuel**.

### Phase A — Intégration (priorité haute)

| # | Sujet | État | Action |
|---|--------|------|--------|
| A1 | **Refactor scènes-first** | Fait (`0189a85`) | Scènes `elements/*.tscn` → `track_element.gd` unique ; `car_view.gd` centralise les pièces ; suppression anciens scripts couche piste / voiture. |
| A2 | **Cache éditeur / LSP** | Corrigé dans le dépôt, à refaire localement | Après pull : reload projet + `godot --headless --path godot --import --quit` (voir section Dépannage ci-dessus). |
| A3 | **Export web** | Après A1 | `./godot/export-web.sh` puis test `http://localhost:6605`. |

**Critère de fin A** : `docker compose` + client headless + serveur (`obstacles piste : 5`) + éditeur sans erreurs sur `elements/*.gd`.

### Phase B — Dette mineure (non bloquante, exercices avancés)

| # | Sujet | Impact | Piste d’implémentation |
|---|--------|--------|-------------------------|
| B1 | **`CarSpecs` par pilote (serveur)** | Fait | `net.gd` : `_specs_by_peer` + `default_car.tres` ; `CarPhysics.step(..., specs)` dans `_server_tick`. Exercice élève : `.tres` différent par slot. |
| B2 | **Kerbs `Line2D` : phase texture** | Fait (cosmétique) | `track_element.gd` : `start_angle` sur `Track.ellipse_points` (Godot 4.7 n’expose pas `Line2D.texture_offset`). |
| B3 | **`TrackCollision.CAR_RADIUS` fixe** | Fait (avec B1) | `CarSpecs.collision_radius()` ; `resolve_tick(..., specs_by_peer)`. `CAR_RADIUS` = fallback sans specs. |

### Phase C — Hors Godot (rappel)

- API Go / Nuxt : pas le flux WS de course ; voir [GUIDE-ELEVES.md](GUIDE-ELEVES.md).
- Branchement futur backend ↔ parties : hors scope du refactor scènes.

### Checklist avant merge `feat/evo-rac6tt`

- [x] Commit phase A + phase B (gameplay / kerbs)  
- [ ] Client headless 200 frames sans erreur script  
- [ ] Serveur `--quit-after 120 -- --server` → log obstacles  
- [ ] README Godot + GUIDE-ELEVES + CODE-GODOT alignés  
- [ ] Éditeur : aucune référence aux anciens `elements/*.gd`

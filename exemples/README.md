# Parcours exemples — Rac6TT (projet-6TT)

Micro-modules pour couvrir la **mise en place de base** de la stack course 2D
multijoueur, en complément du [Guide élèves](../docs/GUIDE-ELEVES.md).

| # | Dossier | Type | Durée | Guide |
|---|---------|------|-------|-------|
| 01 | [01-valider-la-stack](01-valider-la-stack/) | lab + script | 20 min | §4, §13 |
| 02 | [02-reseau-et-ports](02-reseau-et-ports/) | lab | 25 min | §6, §12 infra |
| 03 | [03-donnees-postgres-redis](03-donnees-postgres-redis/) | lab + SQL | 30 min | §7.2–7.3, §10 |
| 04 | [04-api-et-dashboard](04-api-et-dashboard/) | lab | 35 min | §10–11 |
| 05 | [05-godot-mouvement-2d](05-godot-mouvement-2d/) | mini-projet Godot | 45 min | bases 2D |
| 06 | [06-client-web-et-websocket](06-client-web-et-websocket/) | lab | 30 min | §7.5–7.6, §9 |
| 07 | [07-editeur-novnc](07-editeur-novnc/) | lab | 20 min | §7.7 |
| 08 | [08-godot-course-locale](08-godot-course-locale/) | mini-projet Godot | 45 min | §9 physique |
| 09 | [09-godot-reseau-minimal](09-godot-reseau-minimal/) | mini-projet Godot | 45 min | §9 Net/RPC |

## Ordre conseillé

1. Stack opérationnelle : **01 → 02**
2. Données et dashboard : **03 → 04**
3. Godot sans réseau : **05 → 08**
4. Réseau puis intégration jeu complet : **09** puis dossier [`godot/`](../godot/) (Rac6TT)
5. Export navigateur et éditeur conteneur : **06 → 07** (en parallèle possible)

## Schémas partagés

Diagrammes SVG dans [`_assets/`](_assets/) :

- [`carte-ports-6600-6606.svg`](_assets/carte-ports-6600-6606.svg)
- [`flux-dashboard.svg`](_assets/flux-dashboard.svg)
- [`flux-jeu-ws.svg`](_assets/flux-jeu-ws.svg)
- [`autorite-serveur.svg`](_assets/autorite-serveur.svg)

## Prérequis communs (labs 01–07)

```bash
cp -n .env.example .env
docker compose up -d --build
```

Ports par défaut : voir [`.env.example`](../.env.example) (6600–6606).

## Mini-projets Godot (05, 08, 09)

Godot **4.7.2**, depuis la racine du dépôt :

```bash
godot --path exemples/05-godot-mouvement-2d -e --language fr
```

Ces projets sont **indépendants** du montage Docker `./godot` ; ouvrez-les en
local ou via noVNC (6606) en pointant le chemin absolu vers `exemples/...`.

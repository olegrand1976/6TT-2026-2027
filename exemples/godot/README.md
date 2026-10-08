# Parcours exemples Godot & Rac6TT

Neuf modules : labs stack (01–04, 06–07) + mini-projets Godot 4.7.2 (05, 08, 09).
Chaque mini-projet Godot a un **`docker-compose.yml`** (`import` ; serveur **09** sur **8970**).

| # | Dossier | Thème ado | Type |
|---|---------|-----------|------|
| 01 | [01-valider-la-stack](01-valider-la-stack/) | La stack répond ? | lab + `verify.sh` |
| 02 | [02-reseau-et-ports](02-reseau-et-ports/) | Ports du labo 6600–6606 | lab |
| 03 | [03-donnees-postgres-redis](03-donnees-postgres-redis/) | Scores & données | lab + SQL |
| 04 | [04-api-et-dashboard](04-api-et-dashboard/) | Site de stats | lab |
| 05 | [05-mouvement-2d](05-mouvement-2d/) | **Parkour pixel** | projet Godot |
| 06 | [06-client-web-et-websocket](06-client-web-et-websocket/) | Jeu dans le navigateur | lab |
| 07 | [07-editeur-novnc](07-editeur-novnc/) | Godot dans le browser | lab |
| 08 | [08-course-locale](08-course-locale/) | **Hot lap solo** | projet Godot |
| 09 | [09-reseau-minimal](09-reseau-minimal/) | **Lobby multijoueur** | projet Godot |

## Ordre conseillé

**01 → 02 → 03 → 04 → 05 → 08 → 09 → 06 → 07**

## Mini-projets Godot (05, 08, 09)

```bash
godot --path exemples/godot/05-mouvement-2d -e --language fr
cd exemples/godot/09-reseau-minimal && docker compose up -d server
```

Schémas : [`../_assets/`](../_assets/).

## Suite

Jeu complet : [`godot/`](../../godot/) (Rac6TT). Parcours Go : [`../go/`](../go/README.md).

# Mini-projets Rac6TT — contenu pour PowerPoint

Document à copier-coller dans une présentation (une section = une diapositive suggérée).
Dépôt : **projet-6TT** / jeu **Rac6TT** — course 2D multijoueur (Go, Nuxt, Godot, Docker).

---

## Diapositive 1 — Titre

**Rac6TT — parcours mini-projets**

Environnement conteneurisé + exemples progressifs avant le jeu complet

- Public : 6TT (terminale technique)
- Stack principale : ports **6600–6606**
- Parcours exemples : `**exemples/godot/`** (9 modules) · `**exemples/go/**` (8 mini-stacks)

*Notes orateur : insister sur « apprendre par petits blocs autonomes », puis assembler dans le dépôt racine.*

---

## Diapositive 2 — Deux parcours, un même univers


| Parcours              | Dossier           | Idée                                                                       |
| --------------------- | ----------------- | -------------------------------------------------------------------------- |
| **Godot & stack jeu** | `exemples/godot/` | Comprendre Docker, le réseau, les données, puis Godot 2D et le multijoueur |
| **Go & web**          | `exemples/go/`    | APIs HTTP, Postgres, Redis, pages web — thème « soirée course / paddock »  |


Les deux peuvent se faire **en parallèle** (binômes différents) ou **en série** (Godot d’abord, Go ensuite).

Doc détaillée élèves : `**docs/GUIDE-ELEVES.md*`*

---

## Diapositive 3 — Stack principale (lab Godot 01–07)

Un seul `docker compose up` à la racine du dépôt :


| Service          | Port hôte | Rôle pédagogique                  |
| ---------------- | --------- | --------------------------------- |
| PostgreSQL       | 6600      | Données, pgvector (lab 03)        |
| Redis            | 6601      | Compteurs / cache (lab 03)        |
| Backend Go       | 6602      | API REST                          |
| Frontend Nuxt    | 6603      | Dashboard SSR                     |
| Godot headless   | 6604      | Serveur de jeu (WebSocket)        |
| Client web Caddy | 6605      | Jeu HTML5 (`/ws` même origine)    |
| Éditeur noVNC    | 6606      | Godot dans le navigateur (lab 07) |


Validation rapide : `bash exemples/godot/01-valider-la-stack/verify.sh`

---

## Diapositive 4 — Parcours Godot : vue d’ensemble (9 modules)


| #   | Nom              | Thème « ado »          | Type                  | Durée indicative |
| --- | ---------------- | ---------------------- | --------------------- | ---------------- |
| 01  | Valider la stack | « La stack répond ? »  | Lab + script          | 30 min           |
| 02  | Réseau et ports  | Carte 6600–6606        | Lab                   | 45 min           |
| 03  | Postgres & Redis | Scores & données       | Lab + SQL             | 45 min           |
| 04  | API & dashboard  | Site de stats          | Lab                   | 45 min           |
| 05  | Mouvement 2D     | **Parkour pixel**      | **Mini-projet Godot** | 45 min           |
| 06  | Client web & WS  | Jeu dans le navigateur | Lab                   | 45 min           |
| 07  | Éditeur noVNC    | Godot dans le browser  | Lab                   | 30 min           |
| 08  | Course locale    | **Hot lap solo**       | **Mini-projet Godot** | 45 min           |
| 09  | Réseau minimal   | **Lobby multijoueur**  | **Mini-projet Godot** | 45 min           |


**Ordre conseillé :** 01 → 02 → 03 → 04 → **05 → 08 → 09** → 06 → 07

Schémas SVG partagés : `exemples/_assets/`

---

## Diapositive 5 — Labs Godot (01–04) : objectifs

**01 — Valider la stack**  
Vérifier conteneurs, `/api/health`, dashboard, client web, logs Godot.

**02 — Réseau et ports**  
Lire `docker-compose.yml` : qui parle à qui, pourquoi le navigateur n’utilise pas le port 6604 directement.

**03 — Données Postgres & Redis**  
Requêtes SQL, pgvector (intro), `redis-cli INCR` lié à la télémétrie du backend.

**04 — API et dashboard**  
Deux URL Nuxt (`NUXT_INTERNAL_API_URL` vs `NUXT_PUBLIC_API_URL`), route `status.get.ts`, bouton télémétrie.

---

## Diapositive 6 — Mini-projet Godot 05 « Parkour pixel »

**Compétences :** `CharacterBody2D`, gravité, sauts, plateformes 2D.

**Contenu :** petit niveau plateformes (sprites SVG), sans réseau.

**Lancement :**

- Éditeur hôte : `godot --path exemples/godot/05-mouvement-2d -e --language fr`
- Import optionnel : `docker compose run --rm import` dans le dossier du module

**Lien Rac6TT :** prérequis moteur 2D avant la voiture arcade du jeu principal.

---

## Diapositive 7 — Mini-projet Godot 08 « Hot lap solo »

**Compétences :** piste elliptique, `CarState`, `CarPhysics`, tours (angle polaire), caméra.

**Contenu :** une voiture, une piste — **simulation locale** (pas encore serveur autoritaire).

**Lancement :** `godot --path exemples/godot/08-course-locale -e --language fr`

**Lien Rac6TT :** même géométrie de piste et physique que `godot/scripts/shared/` — le jeu complet déplace l’autorité sur le serveur.

---

## Diapositive 8 — Mini-projet Godot 09 « Lobby multijoueur »

**Compétences :** `WebSocketMultiplayerPeer`, nœud `**Net`** au chemin fixe, RPC client → serveur → broadcast.

**Contenu :** cercles colorés, déplacement flèches, plusieurs clients, port dédié **8970** (hors stack 6604).

**Lancement serveur :** `cd exemples/godot/09-reseau-minimal && docker compose up -d server`  
**Client :** `godot --path exemples/godot/09-reseau-minimal -- --client` (2 fenêtres pour tester)

**Lien Rac6TT :** même idée que `godot/scripts/network/net.gd` — autorité serveur, instantanés, pas de triche côté client.

---

## Diapositive 9 — Labs Godot 06 & 07 (après le réseau)

**06 — Client web & WebSocket**  
Export web, Caddy, proxy `/ws`, cookies et handshake (piège documenté dans le guide).

**07 — Éditeur noVNC**  
Travailler dans Godot via le port **6606** ; alternative : éditeur installé sur la machine hôte.

*Placer 06–07 après 09 permet de relier « RPC minimal » → « vrai client Rac6TT dans le navigateur ».*

---

## Diapositive 10 — Parcours Go : vue d’ensemble (8 mini-stacks)

Mini-projets **autonomes** (`docker compose` dans chaque dossier). Ports **6710–6718** (pas de conflit avec 6600–6606).


| #   | Thème ludique                               | Technique           | Port |
| --- | ------------------------------------------- | ------------------- | ---- |
| 01  | **Garage Zéro** — allumer le moteur         | `net/http`          | 6710 |
| 02  | **Podium Live** — classement du soir        | JSON / query        | 6711 |
| 03  | **Garage des pilotes** — équipes & couleurs | Postgres + pgx      | 6712 |
| 04  | **Hype Train** — compteur live              | Redis INCR          | 6714 |
| 05  | **Fan Zone** — landing course               | Caddy static        | 6715 |
| 06  | **Game Launcher** — bouton Jouer + API      | Caddy reverse proxy | 6716 |
| 07  | **Vote de piste** — map du soir             | Redis hash          | 6717 |
| 08  | **Mur du paddock** — messages entre potes   | Redis list          | 6718 |


**Ordre conseillé :** 01 → 02 → 03 → 04 → **07 → 08** → **05 → 06**

---

## Diapositive 11 — Mini-projets Go : à retenir par bloc

**Bloc HTTP / JSON (01–02)**  
Première route, healthcheck, réponses JSON, paramètres query.

**Bloc données (03–04, 07–08)**  
SQL avec pgx ; Redis compteur, hash (votes), list (mur de messages).

**Bloc web (05–06)**  
Fichiers statiques avec Caddy ; **même origine** : page + `/api/...` proxifié (pattern proche du dashboard Nuxt + backend).

Modèle cible : `**backend/main.go`** du dépôt Rac6TT.

---

## Diapositive 12 — Lancer un exemple (démo slide)

**Stack Rac6TT (Godot labs) :**

```text
cp -n .env.example .env
docker compose up -d --build
bash exemples/godot/01-valider-la-stack/verify.sh
```

**Un mini-projet Go :**

```text
cd exemples/go/07-vote-piste
docker compose up -d --build
curl http://127.0.0.1:6717/healthz
```

**Arrêt :** `docker compose down` (ajouter `-v` pour repartir d’une base Postgres vierge en lab 03).

---

## Diapositive 13 — Fil rouge pédagogique

```text
Infra Docker & ports
    → Données (Postgres / Redis) & API
        → Godot 2D solo (05) → course solo (08) → réseau minimal (09)
            → Client web & éditeur (06–07)
                → Jeu Rac6TT complet (dossier godot/ à la racine)
```

Parcours Go en **parallèle** : chaque couche (HTTP, BDD, cache, front) prépare le backend et le dashboard du projet final.

---

## Diapositive 14 — Critères de réussite (élèves)

- Savoir **quel port** appeler depuis le navigateur vs depuis un conteneur.
- Avoir **validé la stack** (script 01) avant de déboguer le jeu.
- Avoir **ouvert et modifié** au moins un mini-projet Godot (05 ou 08) et un lab Go (01 ou 04).
- Comprendre **autorité serveur** (module 09 + schéma `autorite-serveur.svg`).
- Savoir où lire la doc : `**docs/GUIDE-ELEVES.md`**, index `**exemples/README.md**`.

---

## Diapositive 15 — Ressources & suite


| Ressource           | Emplacement                |
| ------------------- | -------------------------- |
| Guide élèves (long) | `docs/GUIDE-ELEVES.md`     |
| Index exemples      | `exemples/README.md`       |
| Parcours Godot      | `exemples/godot/README.md` |
| Parcours Go         | `exemples/go/README.md`    |
| Jeu complet         | `godot/` + stack racine    |
| Dépôt               | GitHub **6TT-2026-2027**   |


**Prochaine étape projet :** contribuer au jeu Rac6TT (WS, API, UI) en s’appuyant sur les mini-projets.

---

## Annexe — Tableau unique (copier dans PowerPoint)

**Godot (9)** — 01 valider · 02 ports · 03 BDD · 04 dashboard · **05 parkour** · 06 web/WS · 07 noVNC · **08 hot lap** · **09 lobby WS**

**Go (8)** — 01 HTTP · 02 JSON · 03 Postgres · 04 Redis · 05 static · 06 proxy · 07 vote · 08 mur

**Ports mémo :** stack **6600–6606** · Go **6710–6718** · ex09 Godot **8970**

---

*Généré pour intégration présentation — aligné sur `exemples/` au commit main du dépôt projet-6TT.*
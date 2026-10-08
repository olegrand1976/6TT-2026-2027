# 01 — Valider la stack

## Objectif

Vérifier que **tous** les services Rac6TT répondent sans modifier le code (checklist guide §4).

## Prérequis

- Docker Compose v2
- Stack démarrée : `docker compose up -d --build` depuis la racine du dépôt

## Durée

~20 minutes (dont tests navigateur).

## Étapes

1. Exécuter le script de validation :
   ```bash
   bash exemples/godot/01-valider-la-stack/verify.sh
   ```
2. **Dashboard** — http://localhost:6603  
   Bandeau **STACK OPERATIONNELLE**, bouton « Envoyer un tick ».
3. **Jeu** — http://localhost:6605 dans **deux** onglets, flèches pour conduire.
4. **Diagnostic WS** — http://localhost:6605/diag.html (proxy `/ws` OK).
5. **Logs** :
   ```bash
   docker compose logs --tail=30 godot
   docker compose logs --tail=20 webclient
   ```

## Critères de réussite

- `verify.sh` sort avec le code **0**
- Deux voitures visibles en multijoueur
- `[6TT] Pilote connecte` dans les logs Godot après ouverture du jeu

## Pièges

- `.env` absent → identifiants Postgres différents de l’example (guide §12).
- Client web vide → premier `up` sans `godot-prepare` terminé ; relancer `docker compose up -d --build`.

## Lien Rac6TT

Checklist officielle : [GUIDE-ELEVES.md §4](../../../docs/GUIDE-ELEVES.md#4-première-séance-checklist).

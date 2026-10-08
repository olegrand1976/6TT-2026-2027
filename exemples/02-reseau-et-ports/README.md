# 02 — Réseau et ports

## Objectif

Comprendre **port hôte** vs **port conteneur**, le rôle de `.env`, et pourquoi la stack utilise **6600–6606**.

## Prérequis

- Module [01](../01-valider-la-stack/) validé (optionnel mais utile)

## Durée

~25 minutes.

## Étapes

1. Ouvrir le schéma [`../_assets/carte-ports-6600-6606.svg`](../_assets/carte-ports-6600-6606.svg).
2. Lister les ports publiés :
   ```bash
   docker compose ps
   grep '_PORT=' .env.example
   grep '_PORT=' .env 2>/dev/null || echo "Créez .env depuis .env.example"
   ```
3. **Exercice hôte → conteneur** : depuis l’hôte, `curl http://localhost:6602/api/health` atteint le backend. Dans le réseau Docker, Nuxt appelle `http://backend:8080` (pas 6602).
4. **Exercice Godot** : le jeu web utilise `ws://localhost:6605/ws` (Caddy), pas `6604` dans le navigateur.
5. Lire [`docker-compose.yml`](../../docker-compose.yml) : repérer `ports:` et `depends_on:` pour `godot-prepare` → `godot` → `webclient`.

## Critères de réussite

- Vous savez expliquer pourquoi `NUXT_INTERNAL_API_URL` ≠ `NUXT_PUBLIC_API_URL`.
- Vous identifiez quel service écoute sur 8999 **à l’intérieur** du réseau Docker.

## Pièges

| Symptôme | Cause |
|----------|--------|
| `port is already allocated` | Conflit avec 5432/8080/… — garder 6600–6606 |
| API OK en curl mais pas dans Nuxt | Mauvaise URL (interne vs publique) |

## Lien Rac6TT

[GUIDE-ELEVES §6](../../docs/GUIDE-ELEVES.md#6-réseau-docker-et-ports) · [CLAUDE.md](../../CLAUDE.md) (règles ports).

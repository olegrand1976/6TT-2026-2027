# 07 — Éditeur Godot noVNC (6606)

## Objectif

Utiliser l’**éditeur Godot dans le navigateur** (Xvfb + noVNC), persistance des fichiers et bonnes pratiques sur un clone neuf.

## Prérequis

- Stack up (`godot-editor` démarre avec `docker compose up -d --build`)

## Durée

~20 minutes.

## Étapes

1. Ouvrir  
   http://localhost:6606/vnc.html?autoconnect=true&resize=scale  
   (plein écran, interface **française**).
2. Dans noVNC : **Scaling mode → Local scaling** si le canvas est coupé.
3. Ouvrir un **autre** projet d’exemple :
   - **Fichier → Ouvrir** → chemin hôte  
     `…/projet-6TT/exemples/05-godot-mouvement-2d`
4. Vérifier la persistance : créer un nœud, sauver — le fichier apparaît dans `./godot/` **uniquement** si vous éditez le projet monté en `/project` (Rac6TT principal). Pour les mini-projets sous `exemples/`, éditez depuis l’hôte ou montez le chemin voulu (doc avancée).
5. Aligner les droits dans `.env` :
   ```bash
   id -u && id -g   # → HOST_UID / HOST_GID
   ```
6. Fichiers copiés à la main dans `godot/` : **Projet → Recharger** ou `docker compose restart godot-editor`.

## Critères de réussite

- Session noVNC stable (pas de boucle `Restarting` — verrous X11 corrigés dans `entrypoint-editor.sh`).
- Vous savez quand utiliser l’éditeur **hôte** (`godot --path godot -e --language fr`) vs noVNC.

## Pièges

- Num Lock inversé → `EDITOR_NUMLOCK=off` dans `.env`, rebuild éditeur.
- Import manuel inutile au 1er up stack — `godot-prepare` + import éditeur au démarrage.

## Lien Rac6TT

[`godot/entrypoint-editor.sh`](../../godot/entrypoint-editor.sh) · [GUIDE §7.7](../../docs/GUIDE-ELEVES.md#77-éditeur-godot-novnc-godot-editor).

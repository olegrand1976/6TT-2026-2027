# Parcours exemples — Rac6TT (projet-6TT)

Deux parcours parallèles, même esprit pédagogique :

| Parcours | Dossier | Contenu |
|----------|---------|---------|
| **Godot & stack jeu** | **[godot/](godot/README.md)** | 9 modules (labs + 3 mini-projets Godot) |
| **Go & web Caddy** | **[go/](go/README.md)** | 8 mini-stacks (ports 6710–6718) |

Documentation longue : [Guide élèves](../docs/GUIDE-ELEVES.md).

## Démarrage stack Rac6TT (labs Godot 01–07)

```bash
cp -n .env.example .env
docker compose up -d --build
bash exemples/godot/01-valider-la-stack/verify.sh
```

## Schémas partagés (parcours Godot)

[`_assets/`](_assets/) — ports, dashboard, WebSocket, autorité serveur.

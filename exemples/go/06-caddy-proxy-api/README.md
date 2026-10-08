# 06 — Game Launcher (Caddy + API)

**Thème ado :** écran « Jouer » qui récupère les infos serveur — même origine, zero CORS galère.

## Démarrage

```bash
docker compose up -d --build
curl -s http://localhost:6716/api/launcher | jq
# http://localhost:6716
docker compose down
```

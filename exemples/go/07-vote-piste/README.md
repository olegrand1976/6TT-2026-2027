# 07 — Vote de piste (Redis)

**Thème ado :** le groupe vote pour la map du soir (comme un sondage Discord).

## Démarrage

```bash
docker compose up -d --build
curl -s http://localhost:6717/api/tracks | jq
curl -s -X POST "http://localhost:6717/api/vote?piste=Ovale%20Neon" | jq
curl -s http://localhost:6717/api/votes | jq
docker compose down
```

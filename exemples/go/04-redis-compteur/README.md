# 04 — Hype Train (Redis)

**Thème ado :** compteur « hype » comme les viewers d’un live — chaque POST = +1 sur le compteur.

## Démarrage

```bash
docker compose up -d --build
curl -s -X POST http://localhost:6714/api/hype | jq
curl -s http://localhost:6714/api/hype | jq
docker compose down
```

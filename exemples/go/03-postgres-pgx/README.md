# 03 — Garage des pilotes (Postgres)

**Thème ado :** ton équipe de course stockée en base — qui roule pour quelle crew ?

## Démarrage

```bash
docker compose up -d --build
curl -s http://localhost:6712/api/drivers | jq
docker compose down
```

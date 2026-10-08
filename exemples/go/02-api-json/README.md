# 02 — Podium Live (classement JSON)

**Thème ado :** classement du soir entre potes, pseudos style jeu en ligne.

## Démarrage

```bash
docker compose up -d --build
curl -s http://localhost:6711/api/podium | jq
curl -s "http://localhost:6711/api/shout?pseudo=Toi" | jq
docker compose down
```

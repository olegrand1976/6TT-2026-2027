# 08 — Mur du paddock (Redis liste)

**Thème ado :** un mini-mur de messages entre pilotes (comme un chat de lobbies).

## Démarrage

```bash
docker compose up -d --build
curl -s -X POST http://localhost:6718/api/messages \
  -H 'Content-Type: application/json' \
  -d '{"pseudo":"TurboZ","message":"Qui fait un duel ce soir ?"}' | jq
curl -s http://localhost:6718/api/messages | jq
docker compose down
```

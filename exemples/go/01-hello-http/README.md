# 01 — Garage Zéro (premier moteur HTTP)

**Thème ado :** tu viens de allumer le moteur du serveur — comme appuyer sur « Start »
dans un jeu, sans graphismes pour l’instant.

## Objectif technique

`net/http`, routes, healthcheck Docker.

## Démarrage

```bash
docker compose up -d --build
curl -s http://localhost:6710/
docker compose down
```

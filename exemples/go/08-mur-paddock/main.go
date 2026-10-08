package main

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/redis/go-redis/v9"
)

const listKey = "rac6tt:mur:paddock"
const maxLen = 120
const maxPseudo = 32

func main() {
	rdb := redis.NewClient(&redis.Options{Addr: env("REDIS_ADDR", "redis:6379")})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		log.Fatal(err)
	}

	addr := env("HTTP_ADDR", ":8080")
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := rdb.Ping(c).Err(); err != nil {
			http.Error(w, "redis down", http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.HandleFunc("GET /api/messages", func(w http.ResponseWriter, _ *http.Request) {
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		msgs, err := rdb.LRange(c, listKey, 0, 19).Result()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		writeJSON(w, map[string]any{"messages": msgs})
	})
	mux.HandleFunc("POST /api/messages", func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 512))
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		var req struct {
			Pseudo  string `json:"pseudo"`
			Message string `json:"message"`
		}
		if err := json.Unmarshal(body, &req); err != nil {
			http.Error(w, "json invalide", http.StatusBadRequest)
			return
		}
		req.Pseudo = strings.TrimSpace(req.Pseudo)
		req.Message = strings.TrimSpace(req.Message)
		if req.Pseudo == "" || req.Message == "" {
			http.Error(w, "pseudo et message requis", http.StatusBadRequest)
			return
		}
		if utf8.RuneCountInString(req.Pseudo) > maxPseudo {
			http.Error(w, "pseudo trop long", http.StatusBadRequest)
			return
		}
		if utf8.RuneCountInString(req.Message) > maxLen {
			http.Error(w, "message trop long", http.StatusBadRequest)
			return
		}
		line := req.Pseudo + " : " + req.Message
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := rdb.LPush(c, listKey, line).Err(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		_ = rdb.LTrim(c, listKey, 0, 49).Err()
		writeJSON(w, map[string]string{"ok": "message poste sur le mur du paddock"})
	})
	log.Printf("[mur-paddock] ecoute sur %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	_ = json.NewEncoder(w).Encode(v)
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

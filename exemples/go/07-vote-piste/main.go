package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

var tracks = []string{"Ovale Neon", "Port Lost Pixel", "Forêt Turbo", "Désert Drift"}

func main() {
	rdb := redis.NewClient(&redis.Options{Addr: env("REDIS_ADDR", "redis:6379")})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		log.Fatal(err)
	}

	addr := env("HTTP_ADDR", ":8080")
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", healthz(rdb))
	mux.HandleFunc("GET /api/tracks", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, map[string]any{"pistes": tracks})
	})
	mux.HandleFunc("GET /api/votes", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, map[string]any{"resultats": tally(rdb)})
	})
	mux.HandleFunc("POST /api/vote", func(w http.ResponseWriter, r *http.Request) {
		name := strings.TrimSpace(r.URL.Query().Get("piste"))
		if name == "" {
			http.Error(w, "param piste requis", http.StatusBadRequest)
			return
		}
		if !containsTrack(name) {
			http.Error(w, "piste inconnue", http.StatusBadRequest)
			return
		}
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		n, err := rdb.HIncrBy(c, "rac6tt:votes:pistes", name, 1).Result()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		writeJSON(w, map[string]any{"piste": name, "votes": n, "message": "Vote enregistre — on lance la map ce soir ?"})
	})
	log.Printf("[vote-piste] ecoute sur %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func containsTrack(name string) bool {
	for _, t := range tracks {
		if t == name {
			return true
		}
	}
	return false
}

func tally(rdb *redis.Client) []map[string]any {
	c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	raw, _ := rdb.HGetAll(c, "rac6tt:votes:pistes").Result()
	type row struct {
		Piste string
		Votes int
	}
	var rows []row
	for _, t := range tracks {
		v := 0
		if s, ok := raw[t]; ok {
			v, _ = strconv.Atoi(s)
		}
		rows = append(rows, row{t, v})
	}
	sort.Slice(rows, func(i, j int) bool { return rows[i].Votes > rows[j].Votes })
	out := make([]map[string]any, len(rows))
	for i, r := range rows {
		out[i] = map[string]any{"piste": r.Piste, "votes": r.Votes}
	}
	return out
}

func healthz(rdb *redis.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, _ *http.Request) {
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := rdb.Ping(c).Err(); err != nil {
			http.Error(w, "redis down", http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	}
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

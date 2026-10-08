package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

const redisKey = "rac6tt:hype:soiree"

func main() {
	rdb := redis.NewClient(&redis.Options{
		Addr: env("REDIS_ADDR", "redis:6379"),
	})
	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
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
	mux.HandleFunc("GET /api/hype", func(w http.ResponseWriter, _ *http.Request) {
		writeHype(w, rdb, false)
	})
	mux.HandleFunc("POST /api/hype", func(w http.ResponseWriter, _ *http.Request) {
		writeHype(w, rdb, true)
	})
	log.Printf("[hype-train] ecoute sur %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func writeHype(w http.ResponseWriter, rdb *redis.Client, incr bool) {
	c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	var n int64
	var err error
	if incr {
		n, err = rdb.Incr(c, redisKey).Result()
	} else {
		n, err = rdb.Get(c, redisKey).Int64()
		if err == redis.Nil {
			n = 0
			err = nil
		}
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"hype":    n,
		"message": "Le chat explose — la course va etre folle !",
	})
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, env("DATABASE_URL", "postgres://demo:demo@db:5432/demo?sslmode=disable"))
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	addr := env("HTTP_ADDR", ":8080")
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		c, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := pool.Ping(c); err != nil {
			http.Error(w, "db down", http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.HandleFunc("GET /api/drivers", func(w http.ResponseWriter, _ *http.Request) {
		c, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		rows, err := pool.Query(c, `SELECT name, team, main_color FROM drivers ORDER BY name`)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()
		type driver struct {
			Name  string `json:"name"`
			Team  string `json:"team"`
			Color string `json:"color"`
		}
		var list []driver
		for rows.Next() {
			var d driver
			if err := rows.Scan(&d.Name, &d.Team, &d.Color); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			list = append(list, d)
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(list)
	})
	log.Printf("[ex-go-03] ecoute sur %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

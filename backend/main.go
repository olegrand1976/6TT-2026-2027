// Backend projet-6TT — API HTTP (Postgres + Redis).
//
// Le multijoueur temps réel du jeu passe par Godot (WebSocket), pas par ce serveur.
// Ce binaire sert surtout à :
//   - /api/health     état Postgres + Redis (utilisé par le frontend Nuxt)
//   - /api/telemetry  exemple Redis
//   - /api/similar    exemple pgvector
//
// Un seul fichier volontairement (cours) : pas de duplication avec la physique Godot.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

const version = "0.2.0"

type server struct {
	db  *pgxpool.Pool
	rdb *redis.Client
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func main() {
	ctx := context.Background()

	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=disable",
		env("DB_USER", "game_user"),
		env("DB_PASSWORD", "game_password"),
		env("DB_HOST", "postgres"),
		env("DB_PORT", "5432"),
		env("DB_NAME", "game_db"),
	)

	db, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("pgxpool: %v", err)
	}
	defer db.Close()

	rdb := redis.NewClient(&redis.Options{Addr: env("REDIS_ADDR", "redis:6379")})
	defer rdb.Close()

	s := &server{db: db, rdb: rdb}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", s.handleLiveness)
	mux.HandleFunc("GET /api/health", s.handleHealth)
	mux.HandleFunc("GET /api/telemetry", s.handleTelemetry)
	mux.HandleFunc("POST /api/telemetry/tick", s.handleTelemetryTick)
	mux.HandleFunc("GET /api/leaderboard", s.handleLeaderboard)
	mux.HandleFunc("GET /api/similar", s.handleSimilar)

	addr := env("HTTP_ADDR", ":8080")
	log.Printf("projet-6TT backend a l'ecoute sur %s", addr)

	srv := &http.Server{
		Addr:              addr,
		Handler:           withCORS(mux),
		ReadHeaderTimeout: 5 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

// withCORS autorise le frontend Nuxt (origine differente en dev) a appeler l'API.
func withCORS(next http.Handler) http.Handler {
	origin := env("CORS_ORIGIN", "*")
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

// handleLiveness ne touche a aucune dependance : sert au healthcheck Docker.
func (s *server) handleLiveness(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status":  "ok",
		"service": "projet-6tt-backend",
		"version": version,
		"time":    time.Now().UTC(),
	})
}

type depStatus struct {
	OK      bool   `json:"ok"`
	Detail  string `json:"detail,omitempty"`
	Error   string `json:"error,omitempty"`
	Latency string `json:"latency,omitempty"`
}

// handleHealth verifie reellement Postgres (+ presence de pgvector) et Redis.
func (s *server) handleHealth(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	deps := map[string]depStatus{
		"postgres": s.checkPostgres(ctx),
		"pgvector": s.checkPgvector(ctx),
		"redis":    s.checkRedis(ctx),
	}

	allOK := true
	for _, d := range deps {
		if !d.OK {
			allOK = false
		}
	}

	status := http.StatusOK
	if !allOK {
		status = http.StatusServiceUnavailable
	}
	writeJSON(w, status, map[string]any{
		"status":       map[bool]string{true: "healthy", false: "degraded"}[allOK],
		"dependencies": deps,
		"time":         time.Now().UTC(),
	})
}

func (s *server) checkPostgres(ctx context.Context) depStatus {
	start := time.Now()
	var version string
	if err := s.db.QueryRow(ctx, "SELECT version()").Scan(&version); err != nil {
		return depStatus{Error: err.Error()}
	}
	return depStatus{OK: true, Detail: version, Latency: time.Since(start).String()}
}

func (s *server) checkPgvector(ctx context.Context) depStatus {
	start := time.Now()
	var version string
	err := s.db.QueryRow(ctx,
		"SELECT extversion FROM pg_extension WHERE extname = 'vector'").Scan(&version)
	if err != nil {
		return depStatus{Error: "extension vector absente: " + err.Error()}
	}
	return depStatus{OK: true, Detail: "pgvector " + version, Latency: time.Since(start).String()}
}

func (s *server) checkRedis(ctx context.Context) depStatus {
	start := time.Now()
	pong, err := s.rdb.Ping(ctx).Result()
	if err != nil {
		return depStatus{Error: err.Error()}
	}
	return depStatus{OK: true, Detail: pong, Latency: time.Since(start).String()}
}

// handleTelemetryTick incremente les compteurs temps reel (demo Redis).
func (s *server) handleTelemetryTick(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	driver := r.URL.Query().Get("driver")
	if driver == "" {
		driver = "anonymous"
	}

	total, err := s.rdb.Incr(ctx, "6tt:telemetry:ticks").Result()
	if err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
		return
	}
	if err := s.rdb.ZIncrBy(ctx, "6tt:telemetry:drivers", 1, driver).Err(); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"driver": driver, "total_ticks": total})
}

// handleTelemetry lit les compteurs temps reel stockes dans Redis.
func (s *server) handleTelemetry(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	total, err := s.rdb.Get(ctx, "6tt:telemetry:ticks").Int64()
	if err != nil && err != redis.Nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
		return
	}

	drivers, err := s.rdb.ZRevRangeWithScores(ctx, "6tt:telemetry:drivers", 0, 9).Result()
	if err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
		return
	}

	top := make([]map[string]any, 0, len(drivers))
	for _, z := range drivers {
		top = append(top, map[string]any{"driver": z.Member, "ticks": z.Score})
	}
	writeJSON(w, http.StatusOK, map[string]any{"total_ticks": total, "top_drivers": top})
}

type lapRow struct {
	Driver    string `json:"driver"`
	Track     string `json:"track"`
	LapTimeMs int32  `json:"lap_time_ms"`
}

// handleLeaderboard lit les meilleurs tours depuis Postgres.
func (s *server) handleLeaderboard(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	rows, err := s.db.Query(ctx, `
		SELECT driver, track, lap_time_ms
		FROM telemetry_samples
		ORDER BY lap_time_ms ASC
		LIMIT 10`)
	if err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
		return
	}
	defer rows.Close()

	laps := make([]lapRow, 0, 10)
	for rows.Next() {
		var l lapRow
		if err := rows.Scan(&l.Driver, &l.Track, &l.LapTimeMs); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		laps = append(laps, l)
	}
	writeJSON(w, http.StatusOK, map[string]any{"laps": laps})
}

// handleSimilar : recherche vectorielle pgvector - les pilotes au style le plus
// proche d'un vecteur de reference passe en query string.
func (s *server) handleSimilar(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	q := r.URL.Query()
	vec := fmt.Sprintf("[%s,%s,%s]",
		env2(q.Get("speed"), "0.9"),
		env2(q.Get("braking"), "0.8"),
		env2(q.Get("consistency"), "0.6"),
	)

	rows, err := s.db.Query(ctx, `
		SELECT driver, track, lap_time_ms, embedding <=> $1::vector AS distance
		FROM telemetry_samples
		ORDER BY distance ASC
		LIMIT 5`, vec)
	if err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": err.Error()})
		return
	}
	defer rows.Close()

	type match struct {
		lapRow
		Distance float64 `json:"distance"`
	}
	matches := make([]match, 0, 5)
	for rows.Next() {
		var m match
		if err := rows.Scan(&m.Driver, &m.Track, &m.LapTimeMs, &m.Distance); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		matches = append(matches, m)
	}
	writeJSON(w, http.StatusOK, map[string]any{"reference": vec, "matches": matches})
}

// env2 renvoie value si c'est un flottant valide, sinon fallback.
func env2(value, fallback string) string {
	if _, err := strconv.ParseFloat(value, 64); err == nil {
		return value
	}
	return fallback
}

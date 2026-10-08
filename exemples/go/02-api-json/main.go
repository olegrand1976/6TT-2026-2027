package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"
)

type score struct {
	Pseudo string `json:"pseudo"`
	Points int    `json:"points"`
	Tag    string `json:"tag"`
}

var podium = []score{
	{Pseudo: "NeonSkid", Points: 9840, Tag: "drift"},
	{Pseudo: "TurboZ", Points: 9210, Tag: "speed"},
	{Pseudo: "PixelRider", Points: 8870, Tag: "rookie"},
	{Pseudo: "ShadowDrift", Points: 8650, Tag: "drift"},
}

func main() {
	addr := env("HTTP_ADDR", ":8080")
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})
	mux.HandleFunc("GET /api/podium", func(w http.ResponseWriter, _ *http.Request) {
		sorted := append([]score(nil), podium...)
		sort.Slice(sorted, func(i, j int) bool { return sorted[i].Points > sorted[j].Points })
		writeJSON(w, map[string]any{"course": "Rac6TT Arcade", "classement": sorted})
	})
	mux.HandleFunc("GET /api/shout", func(w http.ResponseWriter, r *http.Request) {
		pseudo := strings.TrimSpace(r.URL.Query().Get("pseudo"))
		if pseudo == "" {
			pseudo = "Pilote"
		}
		writeJSON(w, map[string]string{
			"pseudo":  pseudo,
			"message": pseudo + " entre en piste — fais chauffer les pneus !",
		})
	})
	log.Printf("[podium-live] ecoute sur %s", addr)
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

package main

import (
	"log"
	"net"
	"os"
	"time"
)

type Config struct {
	Port      string
	JWTSecret string
	TokenTTL  time.Duration
	DBPath    string
}

func loadConfig() Config {
	return Config{
		Port:      envOr("PORT", "8080"),
		JWTSecret: envOr("JWT_SECRET", "dev-secret-change-me"),
		TokenTTL:  24 * time.Hour,
		DBPath:    envOr("DB_PATH", "server.db"),
	}
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func main() {
	cfg := loadConfig()
	if cfg.JWTSecret == "dev-secret-change-me" {
		log.Println("WARNING: using default JWT_SECRET, set the JWT_SECRET env var in production")
	}

	store, err := NewStore(cfg.DBPath)
	if err != nil {
		log.Fatalf("open store: %v", err)
	}
	defer store.Close()

	h := &Handlers{Store: store, Auth: NewAuth(cfg.JWTSecret, cfg.TokenTTL)}

	ln, err := net.Listen("tcp", ":"+cfg.Port)
	if err != nil {
		log.Fatalf("listen: %v", err)
	}
	log.Printf("tcp server listening on %s (db: %s)", ln.Addr(), cfg.DBPath)
	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Printf("accept: %v", err)
			continue
		}
		go h.serveConn(conn)
	}
}

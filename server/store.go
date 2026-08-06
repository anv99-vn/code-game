package main

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	_ "modernc.org/sqlite"
)

var ErrUserExists = errors.New("username already taken")

type Store struct {
	db *sql.DB
}

const usersSchema = `CREATE TABLE IF NOT EXISTS users (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	username TEXT NOT NULL COLLATE NOCASE UNIQUE,
	password_hash TEXT NOT NULL,
	created_at TEXT NOT NULL
)`

func NewStore(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	if err := ensureSchema(db); err != nil {
		db.Close()
		return nil, err
	}
	return &Store{db: db}, nil
}

// ensureSchema creates the users table and migrates pre-existing databases
// so the username UNIQUE constraint is case-insensitive (Player1 == player1).
func ensureSchema(db *sql.DB) error {
	if _, err := db.Exec(usersSchema); err != nil {
		return err
	}
	var createSQL string
	if err := db.QueryRow(`SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'users'`).Scan(&createSQL); err != nil {
		return err
	}
	if strings.Contains(strings.ToUpper(createSQL), "COLLATE NOCASE") {
		return nil
	}
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	for _, stmt := range []string{
		`ALTER TABLE users RENAME TO users_old`,
		`CREATE TABLE users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT NOT NULL COLLATE NOCASE UNIQUE,
			password_hash TEXT NOT NULL,
			created_at TEXT NOT NULL
		)`,
		`INSERT INTO users (id, username, password_hash, created_at) SELECT id, username, password_hash, created_at FROM users_old`,
		`DROP TABLE users_old`,
	} {
		if _, err := tx.Exec(stmt); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (s *Store) Close() error {
	return s.db.Close()
}

func (s *Store) CreateUser(ctx context.Context, username, passwordHash string) error {
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO users (username, password_hash, created_at) VALUES (?, ?, ?)`,
		username, passwordHash, time.Now().UTC().Format(time.RFC3339))
	if err != nil {
		if strings.Contains(err.Error(), "UNIQUE constraint failed") {
			return ErrUserExists
		}
		return err
	}
	return nil
}

func (s *Store) GetUser(ctx context.Context, username string) (string, error) {
	var passwordHash string
	err := s.db.QueryRowContext(ctx,
		`SELECT password_hash FROM users WHERE username = ?`, username).Scan(&passwordHash)
	return passwordHash, err
}

package main

import (
	"context"
	"errors"
	"path/filepath"
	"testing"
)

// newTestStore opens a Store on a fresh SQLite file inside a temp dir so each
// test is isolated and leaves no data behind; the DB is closed on cleanup.
func newTestStore(t *testing.T) *Store {
	t.Helper()
	s, err := NewStore(filepath.Join(t.TempDir(), "test.db"))
	if err != nil {
		t.Fatalf("NewStore: %v", err)
	}
	t.Cleanup(func() { s.Close() })
	return s
}

// TestCreateUserAndGetUser verifies a user can be inserted and then fetched
// back, returning exactly the stored password hash.
func TestCreateUserAndGetUser(t *testing.T) {
	s := newTestStore(t)
	if err := s.CreateUser(context.Background(), "player1", "hash1"); err != nil {
		t.Fatalf("CreateUser: %v", err)
	}
	hash, err := s.GetUser(context.Background(), "player1")
	if err != nil {
		t.Fatalf("GetUser: %v", err)
	}
	if hash != "hash1" {
		t.Errorf("hash = %q, want hash1", hash)
	}
}

// TestCreateUserDuplicate inserts the same username twice and expects the
// second insert to return the sentinel ErrUserExists (checked via errors.Is).
func TestCreateUserDuplicate(t *testing.T) {
	s := newTestStore(t)
	ctx := context.Background()
	if err := s.CreateUser(ctx, "player1", "hash1"); err != nil {
		t.Fatalf("CreateUser: %v", err)
	}
	if err := s.CreateUser(ctx, "player1", "hash2"); !errors.Is(err, ErrUserExists) {
		t.Errorf("second CreateUser err = %v, want ErrUserExists", err)
	}
}

// TestGetUserUnknown fetches a user that was never inserted and expects an
// error (no match).
func TestGetUserUnknown(t *testing.T) {
	s := newTestStore(t)
	if _, err := s.GetUser(context.Background(), "ghost"); err == nil {
		t.Error("expected error for unknown user")
	}
}

// TestCreateUserCaseInsensitiveDuplicate registers usernames that differ only
// by case ("Player1" vs "player1") and expects the second insert to fail with
// ErrUserExists — usernames are unique case-insensitively.
func TestCreateUserCaseInsensitiveDuplicate(t *testing.T) {
	s := newTestStore(t)
	ctx := context.Background()
	if err := s.CreateUser(ctx, "Player1", "hash1"); err != nil {
		t.Fatalf("CreateUser: %v", err)
	}
	if err := s.CreateUser(ctx, "player1", "hash2"); !errors.Is(err, ErrUserExists) {
		t.Errorf("case-insensitive CreateUser err = %v, want ErrUserExists", err)
	}
}

// TestGetUserCaseInsensitive fetches a user with a differently-cased username
// and expects the same stored hash — lookups are case-insensitive too.
func TestGetUserCaseInsensitive(t *testing.T) {
	s := newTestStore(t)
	ctx := context.Background()
	if err := s.CreateUser(ctx, "Player1", "hash1"); err != nil {
		t.Fatalf("CreateUser: %v", err)
	}
	hash, err := s.GetUser(ctx, "player1")
	if err != nil {
		t.Fatalf("GetUser: %v", err)
	}
	if hash != "hash1" {
		t.Errorf("hash = %q, want hash1", hash)
	}
}

package main

import (
	"testing"
	"time"
)

// TestHashAndCheckPassword verifies password hashing:
// - the stored value is a bcrypt hash, never the plaintext password
// - checkPassword returns true for the correct password
// - checkPassword returns false for a wrong password
func TestHashAndCheckPassword(t *testing.T) {
	hash, err := hashPassword("secret123")
	if err != nil {
		t.Fatalf("hashPassword: %v", err)
	}
	if hash == "secret123" {
		t.Error("hash must not be plaintext")
	}
	if !checkPassword(hash, "secret123") {
		t.Error("checkPassword should accept correct password")
	}
	if checkPassword(hash, "wrongpass") {
		t.Error("checkPassword should reject wrong password")
	}
}

// TestIssueAndParseToken checks the JWT round-trip: a token issued for
// "player1" parses back to the same username with no error.
func TestIssueAndParseToken(t *testing.T) {
	a := NewAuth("test-secret", time.Hour)
	token, err := a.IssueToken("player1")
	if err != nil {
		t.Fatalf("IssueToken: %v", err)
	}
	username, err := a.ParseToken(token)
	if err != nil {
		t.Fatalf("ParseToken: %v", err)
	}
	if username != "player1" {
		t.Errorf("username = %q, want player1", username)
	}
}

// TestParseInvalidToken ensures ParseToken rejects malformed input:
// a garbage string and an empty string must both produce an error.
func TestParseInvalidToken(t *testing.T) {
	a := NewAuth("test-secret", time.Hour)
	if _, err := a.ParseToken("garbage"); err == nil {
		t.Error("expected error parsing garbage token")
	}
	if _, err := a.ParseToken(""); err == nil {
		t.Error("expected error parsing empty token")
	}
}

// TestParseTokenWrongSecret verifies HMAC signature validation: a token
// signed with one secret must NOT verify under a different secret.
func TestParseTokenWrongSecret(t *testing.T) {
	signer := NewAuth("signing-secret", time.Hour)
	verifier := NewAuth("different-secret", time.Hour)
	token, err := signer.IssueToken("player1")
	if err != nil {
		t.Fatalf("IssueToken: %v", err)
	}
	if _, err := verifier.ParseToken(token); err == nil {
		t.Error("expected error parsing token signed with different secret")
	}
}

// TestParseExpiredToken ensures the exp (expiry) claim is enforced: a token
// issued with a negative TTL is already expired and must fail to parse.
func TestParseExpiredToken(t *testing.T) {
	a := NewAuth("test-secret", -time.Minute)
	token, err := a.IssueToken("player1")
	if err != nil {
		t.Fatalf("IssueToken: %v", err)
	}
	if _, err := a.ParseToken(token); err == nil {
		t.Error("expected error parsing expired token")
	}
}

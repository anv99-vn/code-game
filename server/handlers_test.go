package main

import (
	"bufio"
	"encoding/binary"
	"encoding/json"
	"net"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// startTestServer boots the real TCP server on an ephemeral port with a fresh
// temp SQLite store and a fixed test secret. Returns the address and cleanup.
func startTestServer(t *testing.T) (string, func()) {
	t.Helper()
	store, err := NewStore(filepath.Join(t.TempDir(), "test.db"))
	if err != nil {
		t.Fatalf("NewStore: %v", err)
	}
	h := &Handlers{Store: store, Auth: NewAuth("test-secret", time.Hour)}
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			go h.serveConn(conn)
		}
	}()
	cleanup := func() {
		ln.Close()
		store.Close()
	}
	return ln.Addr().String(), cleanup
}

// testConn wraps a TCP connection with a buffered reader for framed reads.
type testConn struct {
	conn net.Conn
	r    *bufio.Reader
}

// dial opens a TCP connection to the test server, closed automatically on
// test cleanup.
func dial(t *testing.T, addr string) *testConn {
	t.Helper()
	c, err := net.Dial("tcp", addr)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	t.Cleanup(func() { c.Close() })
	return &testConn{conn: c, r: bufio.NewReader(c)}
}

// send writes one request frame.
func (tc *testConn) send(t *testing.T, req request) {
	t.Helper()
	if err := writeFrame(tc.conn, req); err != nil {
		t.Fatalf("writeFrame: %v", err)
	}
}

// recv reads and decodes the next response frame.
func (tc *testConn) recv(t *testing.T) response {
	t.Helper()
	frame, err := readFrame(tc.r)
	if err != nil {
		t.Fatalf("readFrame: %v", err)
	}
	var resp response
	if err := json.Unmarshal(frame, &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return resp
}

// request sends one request and returns the single response for it.
func (tc *testConn) request(t *testing.T, type_ string, data any) response {
	t.Helper()
	tc.send(t, request{Type: type_, ID: 1, Data: mustJSON(t, data)})
	return tc.recv(t)
}

func mustJSON(t *testing.T, v any) json.RawMessage {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	return b
}

// decodeData re-decodes resp.Data into out.
func decodeData(t *testing.T, resp response, out any) {
	t.Helper()
	b, err := json.Marshal(resp.Data)
	if err != nil {
		t.Fatalf("marshal data: %v", err)
	}
	if err := json.Unmarshal(b, out); err != nil {
		t.Fatalf("decode data: %v", err)
	}
}

// errorCode extracts the code from an error response.
func errorCode(t *testing.T, resp response) string {
	t.Helper()
	var eb errorBody
	decodeData(t, resp, &eb)
	return eb.Code
}

// register sends a register request and returns the raw response.
func register(t *testing.T, tc *testConn, username, password string) response {
	t.Helper()
	return tc.request(t, "register", credentialsData{Username: username, Password: password})
}

// registerOK registers a user, failing unless it returns register_ok, and
// returns the parsed authResponse (username + JWT).
func registerOK(t *testing.T, tc *testConn, username, password string) authResponse {
	t.Helper()
	resp := register(t, tc, username, password)
	if resp.Type != "register_ok" {
		t.Fatalf("register %q: got %q (%+v), want register_ok", username, resp.Type, resp.Data)
	}
	var out authResponse
	decodeData(t, resp, &out)
	if out.Token == "" {
		t.Fatal("register returned empty token")
	}
	return out
}

// TestHealth checks the health message returns health_ok with status ok.
func TestHealth(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	resp := tc.request(t, "health", nil)
	if resp.Type != "health_ok" {
		t.Fatalf("type = %q, want health_ok", resp.Type)
	}
	var out map[string]string
	decodeData(t, resp, &out)
	if out["status"] != "ok" {
		t.Errorf("status = %q, want ok", out["status"])
	}
}

// TestIDEcho ensures the response echoes the request ID back.
func TestIDEcho(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	tc.send(t, request{Type: "health", ID: 42})
	resp := tc.recv(t)
	if resp.ID != 42 {
		t.Errorf("id = %d, want 42", resp.ID)
	}
}

// TestRegisterSuccess registers "player1" and expects register_ok echoing the
// username plus a non-empty JWT.
func TestRegisterSuccess(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	out := registerOK(t, tc, "player1", "secret123")
	if out.Username != "player1" {
		t.Errorf("username = %q, want player1", out.Username)
	}
}

// TestRegisterDuplicate registers "player1" twice and expects the second
// attempt to fail with error code user_exists.
func TestRegisterDuplicate(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	registerOK(t, tc, "player1", "secret123")
	resp := register(t, tc, "player1", "otherpass")
	if code := errorCode(t, resp); code != "user_exists" {
		t.Errorf("code = %q, want user_exists (resp %+v)", code, resp.Data)
	}
}

// TestRegisterDuplicateCaseInsensitive registers "Player1" then "player1" and
// expects the second attempt to fail with user_exists — usernames are unique
// case-insensitively.
func TestRegisterDuplicateCaseInsensitive(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	registerOK(t, tc, "Player1", "secret123")
	resp := register(t, tc, "player1", "otherpass")
	if code := errorCode(t, resp); code != "user_exists" {
		t.Errorf("code = %q, want user_exists (resp %+v)", code, resp.Data)
	}
}

// TestRegisterInvalid sends malformed register payloads and expects error code
// invalid: password under 8 chars, username with a space, username under 3
// chars, username over 32 chars, password over 72 chars, and unparseable data.
func TestRegisterInvalid(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)

	cases := []struct {
		name string
		data credentialsData
	}{
		{"short password", credentialsData{Username: "player1", Password: "short"}},
		{"bad username", credentialsData{Username: "a b", Password: "secret123"}},
		{"short username", credentialsData{Username: "ab", Password: "secret123"}},
		{"long username", credentialsData{Username: strings.Repeat("x", 33), Password: "secret123"}},
		{"long password", credentialsData{Username: "player1", Password: strings.Repeat("x", 73)}},
	}
	for _, tc2 := range cases {
		t.Run(tc2.name, func(t *testing.T) {
			resp := register(t, tc, tc2.data.Username, tc2.data.Password)
			if code := errorCode(t, resp); code != "invalid" {
				t.Errorf("code = %q, want invalid", code)
			}
		})
	}

	t.Run("malformed data", func(t *testing.T) {
		raw := []byte(`{"type":"register","id":1,"data":{bad}`)
		var lb [4]byte
		binary.BigEndian.PutUint32(lb[:], uint32(len(raw)))
		if _, err := tc.conn.Write(lb[:]); err != nil {
			t.Fatalf("write length: %v", err)
		}
		if _, err := tc.conn.Write(raw); err != nil {
			t.Fatalf("write payload: %v", err)
		}
		resp := tc.recv(t)
		if code := errorCode(t, resp); code != "invalid" {
			t.Errorf("code = %q, want invalid", code)
		}
	})
}

// TestLoginSuccess registers then logs in with the correct password and
// expects login_ok with the username and a non-empty JWT.
func TestLoginSuccess(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	registerOK(t, tc, "player1", "secret123")
	resp := tc.request(t, "login", credentialsData{Username: "player1", Password: "secret123"})
	if resp.Type != "login_ok" {
		t.Fatalf("type = %q (resp %+v), want login_ok", resp.Type, resp.Data)
	}
	var out authResponse
	decodeData(t, resp, &out)
	if out.Username != "player1" || out.Token == "" {
		t.Errorf("bad login response: %+v", out)
	}
}

// TestLoginCaseInsensitive registers "Player1" then logs in as "player1" and
// expects login_ok — login is case-insensitive.
func TestLoginCaseInsensitive(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	registerOK(t, tc, "Player1", "secret123")
	resp := tc.request(t, "login", credentialsData{Username: "player1", Password: "secret123"})
	if resp.Type != "login_ok" {
		t.Errorf("type = %q, want login_ok", resp.Type)
	}
}

// TestLoginWrongPassword logs in with a valid username but a wrong password
// and expects error code invalid_credentials.
func TestLoginWrongPassword(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	registerOK(t, tc, "player1", "secret123")
	resp := tc.request(t, "login", credentialsData{Username: "player1", Password: "wrongpass1"})
	if code := errorCode(t, resp); code != "invalid_credentials" {
		t.Errorf("code = %q, want invalid_credentials", code)
	}
}

// TestLoginUnknownUser logs in as a user that was never registered and expects
// error code invalid_credentials — the response does not reveal whether the
// user exists.
func TestLoginUnknownUser(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	resp := tc.request(t, "login", credentialsData{Username: "ghost", Password: "secret123"})
	if code := errorCode(t, resp); code != "invalid_credentials" {
		t.Errorf("code = %q, want invalid_credentials", code)
	}
}

// TestMeWithToken sends me with a valid JWT and expects me_ok with the
// username read from the token sub claim.
func TestMeWithToken(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	out := registerOK(t, tc, "player1", "secret123")
	resp := tc.request(t, "me", map[string]string{"token": out.Token})
	if resp.Type != "me_ok" {
		t.Fatalf("type = %q (resp %+v), want me_ok", resp.Type, resp.Data)
	}
	var me map[string]string
	decodeData(t, resp, &me)
	if me["username"] != "player1" {
		t.Errorf("username = %q, want player1", me["username"])
	}
}

// TestMeWithoutToken sends me with an empty token and expects error code
// invalid_token.
func TestMeWithoutToken(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	resp := tc.request(t, "me", map[string]string{"token": ""})
	if code := errorCode(t, resp); code != "invalid_token" {
		t.Errorf("code = %q, want invalid_token", code)
	}
}

// TestMeWithInvalidToken sends me with a garbage token and expects error code
// invalid_token.
func TestMeWithInvalidToken(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	resp := tc.request(t, "me", map[string]string{"token": "not-a-real-token"})
	if code := errorCode(t, resp); code != "invalid_token" {
		t.Errorf("code = %q, want invalid_token", code)
	}
}

// TestMeWithTokenFromWrongSecret signs a token with a different secret than
// the server uses and expects me to reject it with invalid_token.
func TestMeWithTokenFromWrongSecret(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	other := NewAuth("different-secret", time.Hour)
	token, err := other.IssueToken("player1")
	if err != nil {
		t.Fatalf("IssueToken: %v", err)
	}
	resp := tc.request(t, "me", map[string]string{"token": token})
	if code := errorCode(t, resp); code != "invalid_token" {
		t.Errorf("code = %q, want invalid_token", code)
	}
}

// TestMeWithExpiredToken sends an already-expired token (negative TTL) signed
// with the server's secret and expects me to reject it with invalid_token.
func TestMeWithExpiredToken(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	expired := NewAuth("test-secret", -time.Minute)
	token, err := expired.IssueToken("player1")
	if err != nil {
		t.Fatalf("IssueToken: %v", err)
	}
	resp := tc.request(t, "me", map[string]string{"token": token})
	if code := errorCode(t, resp); code != "invalid_token" {
		t.Errorf("code = %q, want invalid_token", code)
	}
}

// TestUnknownType sends an unrecognized message type and expects error code
// unknown_type.
func TestUnknownType(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)
	resp := tc.request(t, "banana", nil)
	if code := errorCode(t, resp); code != "unknown_type" {
		t.Errorf("code = %q, want unknown_type", code)
	}
}

// TestMalformedJSON sends a raw frame that is not valid JSON and expects an
// error response with code invalid.
func TestMalformedJSON(t *testing.T) {
	addr, cleanup := startTestServer(t)
	defer cleanup()
	tc := dial(t, addr)

	raw := []byte(`{not json`)
	var lb [4]byte
	binary.BigEndian.PutUint32(lb[:], uint32(len(raw)))
	if _, err := tc.conn.Write(lb[:]); err != nil {
		t.Fatalf("write length: %v", err)
	}
	if _, err := tc.conn.Write(raw); err != nil {
		t.Fatalf("write payload: %v", err)
	}

	resp := tc.recv(t)
	if code := errorCode(t, resp); code != "invalid" {
		t.Errorf("code = %q, want invalid", code)
	}
}

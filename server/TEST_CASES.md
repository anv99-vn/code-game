# Server Test Cases

Go TCP auth server (login + register with JWT) test documentation.

## Running the Tests

```
cd server
go test -race ./...
```

## Files

- `auth_test.go` — bcrypt + JWT unit tests
- `handlers_test.go` — TCP protocol integration tests
- `protocol_test.go` — frame read/write unit tests
- `store_test.go` — SQLite persistence tests

Each test uses an isolated temp database (`t.TempDir()`) and an ephemeral
port, so nothing touches the real `server.db` or `PORT`.

## Protocol

Length-prefixed JSON over TCP. Each frame is a 4-byte big-endian length
followed by a JSON payload.

Request: `{"type": "<type>", "id": <int>, "data": {...}}`
Response: `{"type": "<type>_ok"|"error", "id": <echoed>, "data": {...}}`
Error `data` carries `{"code": <code>, "message": <string>}`.

---

## `auth_test.go`

### TestHashAndCheckPassword
Verifies password hashing:
- Input: `hashPassword("secret123")`
- Expected: returned value is a bcrypt hash (not plaintext), `checkPassword` returns `true` for the correct password, `false` for a wrong password.

### TestIssueAndParseToken
JWT round-trip:
- Input: issue token for `player1`, then parse it.
- Expected: no error; parsed username is `player1`.

### TestParseInvalidToken
Malformed input rejection:
- Input: `"garbage"` and `""` tokens.
- Expected: both produce a parse error.

### TestParseTokenWrongSecret
HMAC signature validation:
- Input: token signed with secret A, verified with secret B.
- Expected: parse fails (signature mismatch).

### TestParseExpiredToken
Expiry claim enforcement:
- Input: token issued with negative TTL (`-time.Minute`), so it is already expired.
- Expected: parse fails.

---

## `handlers_test.go`

### TestHealth
- Request: `health` message.
- Expected: `health_ok` with data `{"status":"ok"}`.

### TestIDEcho
- Request: `health` with `id` 42.
- Expected: response echoes `id` 42.

### TestRegisterSuccess
- Request: `register` with `{"username":"player1","password":"secret123"}`.
- Expected: `register_ok`; data contains username `player1` and a non-empty JWT.

### TestRegisterDuplicate
- Request: register `player1` twice (second time with a different password).
- Expected: second attempt returns `error` with code `user_exists`.

### TestRegisterDuplicateCaseInsensitive
- Request: register `Player1`, then register `player1`.
- Expected: second attempt returns `error` with code `user_exists` (usernames are case-insensitively unique).

### TestRegisterInvalid
Table-driven validation, all expecting `error` with code `invalid`:
- password under 8 chars (`"short"`)
- username containing a space (`"a b"`)
- username under 3 chars (`"ab"`)
- username over 32 chars (33 `x`'s)
- password over 72 chars (73 `x`'s)
- unparseable `data` field (`{bad`)

### TestLoginSuccess
- Request: register `player1`/`secret123`, then `login` with the same credentials.
- Expected: `login_ok`; data contains username `player1` and a non-empty JWT.

### TestLoginCaseInsensitive
- Request: register `Player1`/`secret123`, then login as `player1`/`secret123`.
- Expected: `login_ok` (login is case-insensitive).

### TestLoginWrongPassword
- Request: register `player1`, then login with a wrong password.
- Expected: `error` with code `invalid_credentials`.

### TestLoginUnknownUser
- Request: login as `ghost` (never registered).
- Expected: `error` with code `invalid_credentials` — the response does not reveal whether a user exists.

### TestMeWithToken
- Request: `me` with a valid JWT (from register) in `data.token`.
- Expected: `me_ok`; username read from the JWT `sub` claim.

### TestMeWithoutToken
- Request: `me` with `data.token` empty.
- Expected: `error` with code `invalid_token`.

### TestMeWithInvalidToken
- Request: `me` with `data.token` = `"not-a-real-token"`.
- Expected: `error` with code `invalid_token`.

### TestMeWithTokenFromWrongSecret
- Request: `me` with a token signed using a different secret.
- Expected: `error` with code `invalid_token` (signature verified server-side).

### TestMeWithExpiredToken
- Request: `me` with an already-expired token issued with the server's secret.
- Expected: `error` with code `invalid_token`.

### TestUnknownType
- Request: unrecognized message type `banana`.
- Expected: `error` with code `unknown_type`.

### TestMalformedJSON
- Request: send a raw frame whose payload is not valid JSON.
- Expected: `error` with code `invalid`.

---

## `protocol_test.go`

### TestFrameRoundTrip
Writes a frame to a buffer and reads it back:
- Expected: length prefix stripped, payload decodes to the original value, buffer fully drained.

### TestReadFrameEmptyInput
- Input: reader with no data (closed connection).
- Expected: `readFrame` returns an error.

### TestReadFrameTooLarge
- Input: a length prefix above `maxFrameSize` (1 MB).
- Expected: `readFrame` rejects it before reading the payload.

---

## `store_test.go`

### TestCreateUserAndGetUser
- Input: `CreateUser("player1", "hash1")` then `GetUser("player1")`.
- Expected: no error; returned hash equals `"hash1"`.

### TestCreateUserDuplicate
- Input: `CreateUser("player1", ...)` twice.
- Expected: second insert returns sentinel `ErrUserExists` (via `errors.Is`).

### TestCreateUserCaseInsensitiveDuplicate
- Input: `CreateUser("Player1", ...)` then `CreateUser("player1", ...)`.
- Expected: second insert returns `ErrUserExists` (case-insensitive unique constraint).

### TestGetUserCaseInsensitive
- Input: `CreateUser("Player1", "hash1")` then `GetUser("player1")`.
- Expected: no error; returned hash equals `"hash1"`.

### TestGetUserUnknown
- Input: `GetUser("ghost")` (never inserted).
- Expected: returns an error.

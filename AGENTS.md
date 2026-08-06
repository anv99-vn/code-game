# Project Rules

## Git

Only commit changes made during the current session. Do not commit pre-existing uncommitted changes.

After pushing, check the CI action status. If it fails, investigate and fix the issues before proceeding.

When merging a pull request:
1. Rebase the branch onto main before merging.
2. Delete the branch locally and remotely after successful merge.

When creating a tag:
1. Create or update a `CHANGELOG.md` file with the tag version, date, and list of changes.
2. Commit the changelog update before creating the tag.

## Screenshots

When taking a screenshot, rename the file to describe its purpose.
Use descriptive names like `main-menu.png`, `inventory-ui.png`, `bug-missing-texture.png`.
Avoid generic names like `screenshot1.png` or `tmp.png`.

Always save screenshots to `addons/godot_mcp/cache/screenshots/` (use `save_to: "res://addons/godot_mcp/cache/screenshots/<descriptive-name>.png"` with the take_screenshot tool). Do not save screenshots anywhere else.

## Thread Attachments

When a file is attached to a thread, only read that specific file. Do not read other files in the project unless explicitly asked.

## Testing

When running only a test scene, update autoloads to update data as needed for the test.

## GDScript

Use the method call syntax for deferred calls: `my_func.call_deferred()` instead of `call_deferred("my_func")`.

## Server

Go TCP auth server in `server/` (login + register with JWT).

- Build: `go build -o server.exe .` (run from `server/`)
- Test: `go test -race ./...` (run from `server/`)
- Run: `server.exe` — listens on `PORT` (default 8080)
- Env config: `PORT`, `JWT_SECRET`, `DB_PATH` (SQLite, default `server.db`)
- Protocol: length-prefixed JSON over TCP. Each frame is a 4-byte big-endian length followed by a JSON payload.
- Request: `{"type": "<type>", "id": <int>, "data": {...}}`
- Messages: `health`, `register` {username,password}, `login` {username,password}, `me` {token}
- Response: `{"type": "<type>_ok"|"error", "id": <echoed>, "data": {...}}`. Errors carry `{code, message}` (e.g. `user_exists`, `invalid_credentials`, `invalid_token`, `invalid`, `unknown_type`).
- Tests are manual via a TCP client (e.g. PowerShell `TcpClient` or a small Go program) against a running instance.

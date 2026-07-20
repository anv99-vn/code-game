# Code Review — `code-game`

Review performed across the whole project (GDScript 4.7, scenes, config, CI).

## 1. Style

- Generally consistent and idiomatic GDScript 4 (snake_case, typed `@onready` vars, signals with typed args, `:=` for inference). A few issues remain:
- **`_current_action: String`** in `game_ui.gd:10` uses a sentinel empty string. With three actions and growing, switch to an enum:
  ```gdscript
  enum Action { NONE, CHOP, MINE, PAN }
  var _current_action: Action = Action.NONE
  ```
  Then `match` on it; `InputEventAction.action` still needs a string, supplied by a small `_action_name()` getter.
- **Magic numbers** scattered: respawn flash color `Color(1, 0.3, 0.3)` (now exposed via `flash_color` on `HarvestableResource`), per-resource shake amount (`tree.tscn` uses 4.0, stone/gold use the default 3.0 — now exposed via `shake_amount`). Remaining magic numbers (label offsets, Area2D radii) live in scene files and are acceptable.
- **`scripts/game.gd`** is a single-line empty class (`extends Node2D`). Delete it or document why it exists.
- **`game_ui.gd:6–8`** drops type annotations on `settings_dropdown` / `lang_dropdown`. The dropdown scripts have no `class_name`. Add `class_name SettingsDropdown` / `class_name LangDropdown` so `@onready var settings_dropdown: SettingsDropdown` is valid and gives IDE autocomplete.
- **Mixed use of `tr` / `TranslationServer`.** `_on_language_selected` in `login.gd:73` re-translates controls by hand; nodes added later silently stay untranslated. Connect to `NotificationServer`/`NOTIFICATION_TRANSLATION_CHANGED` on the scene root, or call it on the root.

## 2. Best Practices / Architecture

### Resource duplication — FIXED
`tree.gd`, `stone.gd`, `gold_source.gd` were ~95% identical (~147 lines each). Extracted into a single `HarvestableResource` base class (`scripts/harvestable_resource.gd`) driven by `@export` NodePath/String fields. The three scenes now share one script instance via `script = ExtResource("harvestable_resource")` with per-resource `main_sprite_path = NodePath("TreeSprite")`, `config_key = "tree"`, `action = "chop"`, etc.

- Eliminated ~440 lines of duplication; the three `.gd` subclass files are deleted.
- Dead per-resource signals (`tree_chopped`, `stone_mined`, `gold_panned`) — confirmed via grep to have no consumers — are removed.
- The three per-resource `*_proximity_changed` signals unified to a single `proximity_changed(nearby: bool)`.
- `GLOW_SHADER` is preloaded once (previously duplicated 3×).
- `_respawn_glow` tween now `bind_node(sprite)` + `is_instance_valid` guard (fixes the stale-sprite-reference race flagged in point 3).

### The `node_added`-driven wiring pattern is fragile

Every autoload (`interaction_manager.gd`, `resource_manager.gd`, `session_manager.gd`, `world_manager.gd`) connects `get_tree().node_added` to discover nodes by group and connect signals. Problems:

1. `node_added` fires *before* the node's `_ready()` — `@onready` children aren't ready yet. We got away with it because only signals are touched, but it's brittle.
2. **`world_manager.gd:90`** calls `generate_objects(node, player.global_position)` from `_on_node_added` synchronously. **Active error in the project** — at runtime in `game.tscn`, `world_manager._try_place` emits ~13 errors of the form `Parent node is busy setting up children, add_child() failed` (see `world_manager.gd:83 → _try_place` stack trace). Fix: defer the whole call.
   ```gdscript
   func _on_node_added(node: Node) -> void:
       if node.is_in_group("game_scene") and node is Node2D:
           var player := node.get_node_or_null("Player")
           if player and player is CharacterBody2D:
               generate_objects.call_deferred(node, player.global_position)
   ```
3. **Discovery via stringly-typed `has_signal` / `has_method`** (interaction_manager, session_manager) is duck typing with no compile-time check. A typo in `_on_focus_changed` silently breaks connection. Prefer registering via a typed API:
   ```gdscript
   InteractionManager.register_interactable(self)  # called by resource _ready()
   ```
   Making the contract explicit also makes managers mockable for tests.
4. **No disconnect on `queue_free`.** `InteractionManager._nearby` holds references to freed nodes; `_update_focus` currently limps along with `is_instance_valid`. Connect `tree_exiting` (or the resource's ` player_exited`) to clean `_nearby` proactively.

### `InteractionManager._player` is set but never cleared

`interaction_manager.gd:35` sets `_player = body` on first `player_entered` and never clears it. If the player is freed (scene change), `_player` becomes a dangling reference used by `_update_focus`. Validate with `is_instance_valid(_player)` at the top of `_update_focus` and null it when `_nearby` empties.

### `_update_focus` early-break when `_player` is null

`interaction_manager.gd:57–59`:
```gdscript
else:
    closest = obj
    break
```
Arbitrary fallback. Safer to leave `closest = null` so focus clears when the player is unknown.

### Hardcoded credentials

`login.gd:44`:
```gdscript
if username == "admin" and password == "admin":
```
Combined with `_save_credentials` (`login.gd:51`) which stores the password **in plaintext** to `user://login.cfg` — a real best-practice issue even for a prototype:

- Never ship saved passwords in plaintext. Store a token or a hashed value:
  ```gdscript
  config.set_value("login", "password_hash", password.sha256_text())
  ```
- `session_manager.has_saved_credentials` (`session_manager.gd:20`) only checks the username — returns `true` for an empty-password file. Validate both fields.
- Per `AGENTS.md` ("never expose secrets in code"), the hardcoded `admin/admin` qualifies as a secret in code. Move to a non-committed config or remove once a real backend exists.
- Inject an `authenticator: Callable` property so tests can supply their own.

### `_unhandled_input` round-trip for the mobile action button

`game_ui.gd:56` synthesizes an `InputEventAction` through `Input.parse_input_event` for the mobile action button. This re-enters `_unhandled_input` on every node, including other resources if multiple end up nearby. Consider sending the event directly to the focused node:
```gdscript
var focused := InteractionManager.get_focused()
if focused and focused.has_method("_interact"):
    focused._interact()
```
Removes the global input round-trip and any chance of multi-trigger.

### `yaml_parser.gd` is a YAML-subset hand parser

It exists only to feed `resources.yml`. Concerns:

1. **No tests.** A hand-rolled parser is exactly the kind of code that begs for unit tests.
2. **Silent failure could be louder.** Malformed lines are dropped with no warning. At least `push_warning` on unrecognized lines so `resources.yml` typos surface.
3. `resources.yml` is flat key/value under sections — Godot's `ConfigFile` would suffice. Unless you specifically need YAML, drop the parser and use a `.cfg` to remove custom code and a test surface.

### `YAMLParser.load_file` returns `{}` on failure

`tree.gd` then does `config.has("tree")` — fine, but `FileAccess` also populates `FileAccess.get_open_error()`. Logging it makes disk-permission issues debuggable:
```gdscript
var err := FileAccess.get_open_error()
push_error("YAMLParser: open failed (%d): %s" % [err, path])
```

## 3. Error Handling

- **`world_manager._try_place`** (`world_manager.gd:65`) returns `null` on failure but the caller (`generate_objects:57`) ignores the return. Count failures and log a summary; ideally retry with relaxed `min_distance_between` after N failures. Right now you silently end up with fewer objects than configured and `objects_generated` still emits.
- **`session_manager.has_saved_credentials`** doesn't validate the password field. Surface corrupt files with a warning and treat as "no creds."
- **`_save_credentials` return value ignored** (`login.gd:55`). `config.save()` returns `Error`; show `error_label.text = tr("ERROR_SAVE_FAILED")` on failure.
- **`_load_credentials.call_deferred`** (`login.gd:33`) silently returns on load failure. If a saved session exists but the file is corrupt, the user gets a blank login with no warning — show a non-blocking banner.
- **`game_ui._unhandled_input`** (`game_ui.gd:104`) doesn't check `event.is_echo()`. Add `if event.is_echo(): return` early.
- **`player.gd:18`** casts `_click_effect_scene.instantiate() as Node2D`. If the scene root changes type, this silently returns `null` and crashes on the next line. Use `instantiate()` and assert, or guard.
- **`HarvestableResource._ready`** now `assert`s all six NodePaths are set and the right type — so a misconfigured scene fails loudly at startup instead of NPE-ing later. (Note: in export/release builds `assert` is stripped — promote to explicit `if x == null: push_error(...); return` if you want the guard in shipped builds.)

## 4. Testing

**Zero tests in the project.** CI (`build.yml`) only does an `--import` and export. A syntax error in a resource script is currently caught at export time, which is expensive. Concrete gap list:

| Concern | Test approach |
|---|---|
| `YAMLParser` parsing | Unit tests: feed strings, assert returned dict. Pure function, trivial to test. |
| `ResourceManager.add_resource` / `reset` | Unit test: instantiate scene-free, assert totals, assert signal emission counts. |
| `WorldManager._try_place` placement | Mock RNG via an internal `RandomNumberGenerator` with a fixed seed; assert no overlaps, min-distance respected, `null` returned after exhausting attempts without crashing. |
| `InteractionManager._update_focus` | Construct fake Node2D stand-ins, set `_nearby`, emit `focus_changed`, assert the nearest one wins. |
| `SessionManager.login/logout` | Inject a credentials path (or override `has_saved_credentials` for tests). |
| `Login.gd._on_login_pressed` | Test invalid creds → error_label set; valid creds → `login_requested` emitted; empty fields → `ERROR_EMPTY`. Inject an `authenticator: Callable`. |
| `HarvestableResource` | Integration smoke test: instance `tree.tscn`, add to tree, assert `harvested` fires on `chop` action, health decreases by `per_hit`, depletion grants `bonus_on_deplete`, respawn restores `_health`. **Now that all three resources share one script, one parametric test covers all three** — pass a fixture list `(tree.tscn, "chop"), (stone.tscn, "mine"), (gold_source.tscn, "pan")`. |

Add a `tests/` folder, a `tests/runtests.gd` entrypoint (GUT or bare `assert` script), and a second CI job that runs them before the export step.

Testability changes still needed:

- `world_manager.generate_objects` uses `randf_range` directly. Replace with an internal `var _rng := RandomNumberGenerator.new()` and `_rng.seed = ...` so tests get deterministic placement.
- `session_manager.has_saved_credentials` uses a hardcoded `"user://login.cfg"`. Make it a public `var credentials_path := "user://login.cfg"` so tests point at `res://tests/fixtures/`.
- `login.gd._on_login_pressed` validates against a hardcoded constant — inject an `authenticator: Callable` property.

## 5. Documentation

- **No `class_name` on dropdowns/managers.** Add `class_name SettingsDropdown`, `class_name LangDropdown`, `class_name InteractionManager`, etc. Turns `has_signal("harvested")` string checks into typed references and gives IDE autocomplete.
- **No docstrings.** Each manager has non-obvious behavior (signal discovery via `node_added`, focus math, deferred login navigation). Add `##` doc above each public function and above `_ready` for the autoloads explaining the discovery contract:
  ```gdscript
  ## Listens for nodes joining groups ["trees","stones","gold_sources"] and wires
  ## their player_entered/player_exited signals to the focus system. Resources are
  ## expected to emit `player_entered(body)` from their detection Area2D.
  ```
- **`data/resources.yml`** has additional keys (`action`, `group`) that **no script reads**. Either consume them (so a new resource type can be added purely via config + scene) or remove them and document why.
- **`README.md`** is missing. A one-pager describing the game loop (login → game → harvest → respawn → logout), how to run, and the autoload table would help new contributors.
- **`AGENTS.md`** is excellent (rare and appreciated). Consider a short `CONTRIBUTING.md` covering project layout and "how to add a new harvestable resource" — now that there's one script, the steps are: duplicate a scene, set the 9 `@export` fields, add the config block in `resources.yml`.

## Highest-impact fixes (short list)

1. **[DONE] Extract `HarvestableResource` base class** + delete 3 subclass files — ~440 lines removed, behavior unified.
2. **Add GUT test runner + unit tests** for `YAMLParser`, `ResourceManager`, `WorldManager._try_place` (inject seeded RNG), `InteractionManager._update_focus`, login validation, and a parametric `HarvestableResource` smoke test. Wire into CI before the export step.
3. **Defer `generate_objects`** in `world_manager._on_node_added` — eliminates the 13 currently-active "Parent node is busy setting up children" runtime errors in `game.tscn`.
4. **Remove hardcoded `admin/admin` from `login.gd:44`** and stop persisting the password in plaintext (`login.gd:51`). Replace with `password.sha256_text()` storage at minimum.
5. **Validate `_player` in `InteractionManager._update_focus`** to fix the dangling-reference race.
6. **Delete unused `resources.yml` keys** (`action`, `group`) — or actually consume them so a new resource type is scene+config only.
7. **Document the `node_added` discovery contract** with `##` docstrings on each autoload; consider replacing with explicit `register_*()` calls for testability.

## Files touched in this refactor

- `scripts/harvestable_resource.gd` — new (single shared script, ~180 lines).
- `scripts/tree.gd`, `scripts/stone.gd`, `scripts/gold_source.gd` — deleted.
- `scenes/tree.tscn`, `scenes/stone.tscn`, `scenes/gold_source.tscn` — now reference `harvestable_resource.gd` with per-resource `@export` fields.
- `CODE_REVIEW.md` — this file.

## Verification

- `scenes/tree.tscn`, `scenes/stone.tscn`, `scenes/gold_source.tscn` load standalone in the editor (0 parse errors).
- Main scene (`main.tscn`) launches and runs (0 errors).
- Pre-existing `world_manager` `add_child` race in `game.tscn` is **untouched and unrelated** to this refactor — see point 3 in "Error Handling" for the one-line fix.
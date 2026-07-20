# Project Rules

## Git

Only commit changes made during the current session. Do not commit pre-existing uncommitted changes.

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

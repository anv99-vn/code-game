# Release Notes

## v2.5.0 (2026-08-03)

Simplify Windows CI to a single build with manual dispatch support.

- Split monolithic build workflow into separate `release`, `build-windows`, and `build-android` workflows
- Cache `.godot` import directory across runs to speed up reimports
- Support `workflow_dispatch` on `build-windows` — artifacts download instead of attaching to a release
- Remove the 3-variant renderer matrix (opengl/vulkan/directx); CI now builds a single `Code-Game.exe`

## v2.4.0

Add `AssetRegistry` class to centralize all asset paths as typed constants.

- New `scripts/asset_registry.gd` with 39 constants (icons, scenes, shaders, data, translations)
- New `scripts/tools/generate_asset_registry.gd` editor tool to regenerate after adding assets
- Replace all hardcoded `res://` paths across `game_ui`, `game`, `login`, `main`, `player`, `harvestable_resource`

## v2.3.1

Fix Windows matrix renderer patching so each variant actually uses its intended rendering backend.

- Use INI-relative keys (`renderer/rendering_method`, `rendering_device/driver.windows`, `gl_compatibility/driver.windows`) instead of doubled-prefix keys that Godot silently ignores
- Each variant now exports with the correct driver: OpenGL uses `opengl3_angle`, Vulkan uses `vulkan`, DirectX uses `d3d12`

## v2.3.0

Build 3 Windows variants from a single GitHub Actions matrix.

- `Code-Game-opengl.exe` — OpenGL via ANGLE (`gl_compatibility` + `opengl3_angle`)
- `Code-Game-vulkan.exe` — Vulkan (`forward_plus` + `vulkan`)
- `Code-Game-directx.exe` — DirectX 12 (`forward_plus` + `d3d12`)

Each variant patches `project.godot` and renames the exported binary before upload.

## v2.2.1

Switch Windows export rendering driver to DirectX 12.

- Set `rendering/rendering_device/driver.windows` to `d3d12` in project.godot
- Enabled D3D12 Agility SDK multiarch in export preset
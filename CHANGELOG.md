# Release Notes

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
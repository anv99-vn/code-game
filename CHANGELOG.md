# Changelog

## v2.3.0 - 2026-07-21

- Build Windows export as 3 variants using a GitHub Actions matrix: OpenGL (`opengl3_angle`, gl_compatibility), Vulkan (`vulkan`, forward_plus), and DirectX 12 (`d3d12`, forward_plus). Each variant patches `project.godot` and renames the exported binary (`Code-Game-opengl.exe`, `Code-Game-vulkan.exe`, `Code-Game-directx.exe`).

## v2.2.1 - 2026-07-21

- Switch Windows export rendering driver from Vulkan to DirectX 12 (d3d12) via `rendering/rendering_device/driver.windows` in project.godot.
import { cp, mkdir, readdir, rm, stat } from "node:fs/promises"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"

const root = resolve(fileURLToPath(new URL("..", import.meta.url)))
const source = resolve(root, "godot-mcp", "addons", "godot_mcp")
const destination = resolve(root, "addons", "godot_mcp")
const cache = resolve(destination, "cache")

try {
  if (!(await stat(source)).isDirectory()) throw new Error("not a directory")
} catch {
  throw new Error("Godot MCP submodule is missing. Run: git submodule update --init godot-mcp")
}

await mkdir(destination, { recursive: true })
for (const entry of await readdir(destination)) {
  if (resolve(destination, entry) !== cache) {
    await rm(resolve(destination, entry), { recursive: true, force: true })
  }
}
await cp(source, destination, { recursive: true, force: true })

console.log("Synced godot-mcp/addons/godot_mcp -> addons/godot_mcp")

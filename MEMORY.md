# Memory

- Godot version detected: `4.6.2.stable.official.71f334935`.
- Codex project-level MCP server `godot` is configured in `.codex/config.toml` and visible in `codex mcp list`.
- Current prototype intentionally uses GDScript and generated UI controls instead of C# scene builders because the existing project is a small non-.NET Godot project.
- First playable version uses click-to-select/click-to-place. Dragging can be added later without changing the rules model.
- Visual verification screenshot: `screenshots/prototype/frame00000001.png`.
- Rule smoke test command: `/Applications/Godot.app/Contents/MacOS/Godot --headless --script test/rule_smoke.gd`.

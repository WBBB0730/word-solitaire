# Memory

- Godot version detected: `4.6.2.stable.official.71f334935`.
- Codex project-level MCP server `godot` is configured in `.codex/config.toml` and visible in `codex mcp list`.
- Current prototype intentionally uses GDScript and generated UI controls instead of C# scene builders because the existing project is a small non-.NET Godot project.
- First playable version uses click-to-select/click-to-place. Dragging can be added later without changing the rules model.
- Visual verification screenshot: `screenshots/prototype/frame00000001.png`.
- Rule smoke test command: `/Applications/Godot.app/Contents/MacOS/Godot --headless --script test/rule_smoke.gd`.
- Added a start menu overlay in `scripts/main.gd`; gameplay input is gated by `menu_active` until the player presses “开始游戏”.
- Start menu visual verification screenshot: `screenshots/start_menu/frame00000001.png`.
- Audio assets live under `assets/audio/`; `scripts/main.gd` creates persistent AudioStreamPlayer nodes for looping BGM and card-flip SFX.
- Audio gains use a base-plus-trim model in `scripts/main.gd`: music base `-8.0 dB`; SFX base `-1.2 dB`; card flip trim `-1.4 dB`; button click trim `-0.6 dB`.
- Starting or restarting a round uses a slightly darker green top/bottom curtain with a subtle 4px seam line plus faint highlight; it closes over the current screen, swaps the deal while covered, holds briefly, then opens. It clears `previous_card_positions` before rendering the new deal to prevent stale card-id movement.
- Empty category slots in area 3 use a balanced soft-yellow translucent fill with a brighter yellow dashed outline and no plus sign, so they read as category-card drop slots rather than buttons.
- Initial deal now guarantees the four bottom visible board cards include at least one category card and at least two word cards, using minimal random swaps only when the natural random deal misses those constraints.
- `scripts/main.gd` was split so scene/UI orchestration remains in `main.gd`, while category picking lives in `scripts/category_selector.gd`, solvability/step estimation lives in `scripts/deal_solver.gd`, and BGM/SFX setup lives in `scripts/game_audio.gd`.
- The full category/word library now lives in `scripts/category_library.gd`; expand future card pools there instead of editing `scripts/main.gd`.
- Category selection now rejects cross-category conflict tokens, preventing misleading same-round pairs such as `茶几` and `茶盘` while still allowing same-category shared tokens such as `足球/篮球/网球`.

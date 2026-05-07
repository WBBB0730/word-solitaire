# Plan

## Main Build

- [x] Capture confirmed game rules in `docs/game_rules.md`.
- [x] Build a playable Godot 2D prototype with four areas.
- [x] Implement draw pile, wash-back, click-to-move, collection, steps, win, and fail states.
- [x] Validate the project with Godot headless/editor run.
- [x] Capture a screenshot for visual verification.
- [x] Add rewarded-ad abstraction layer with editor/ad_bypass debug provider.
- [x] Convert hint/undo props from per-round counts to persisted permanent inventory.
- [x] Add rewarded-ad refill flow for hint and undo props; rewards are immediately consumed to perform the requested action.
- [x] Add step-out rewarded-ad flow: “增加步数” grants +20 steps and can succeed once per round.

## Verification Criteria

- [x] Project opens and runs `res://scenes/main.tscn` without script errors.
- [x] The screen shows areas 1, 2, 3, and 4 in a vertical mobile layout.
- [x] Clicking the deck draws cards into area 1 and consumes steps.
- [x] When the deck is empty, clicking it washes area 1 back into area 2 and consumes steps.
- [x] Category cards can enter area 3 and then absorb matching word cards.
- [x] Same-category word groups in area 4 move together.
- [x] Clearing all cards and categories wins; running out of steps before clearing fails.
- [x] Hint/undo zero-inventory buttons show an ad badge and can refill through rewarded ads when the action is otherwise valid.
- [x] Hint/undo ad rewards can be used repeatedly because their inventory is permanent and ads are not round-limited.
- [x] Prop inventory persists through `user://settings.cfg` and is restored on the next scene startup.
- [x] The editor-only `上上下下左右左右BABA` cheat toggles rewarded-ad bypass for the current session.
- [x] Step-out rewarded ads add 20 steps and hide after one successful use in the current round.

## Latest Verification Commands

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/prop_ad_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/extra_steps_ad_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/ad_cheat_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/prop_inventory_persistence_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/prop_system_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/available_step_end_state_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/settings_menu_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/start_menu_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/button_click_sfx_scope_smoke.gd`
- `git diff --check`

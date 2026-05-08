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
- [x] Integrate the real AdMob SDK plugin behind the rewarded-ad abstraction, using Google test IDs by default.
- [x] Add a Vercel-compatible Web rewarded-ad bridge through Google H5 Ad Placement API test mode.

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
- [x] Godot editor runs enable rewarded-ad bypass by default without a keyboard trigger.
- [x] Step-out rewarded ads add 20 steps and hide after one successful use in the current round.
- [x] Android export uses Gradle build, includes AdMob/Google Mobile Ads dependencies, and sets required network permissions.
- [x] Web export uses `web/shell.html` to load Google H5 Ad Placement API in test mode and expose the Godot JS bridge.
- [x] Web rewarded flow waits for Google H5 `onReady`, opens the official mock rewarded ad directly without a custom confirmation prompt, and grants reward after `adViewed`.
- [x] Add lightweight Web ad hardening: one-shot request ids, frozen JS bridge, reward-state revalidation, and prop inventory checksum.

## Latest Verification Commands

- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/prop_ad_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/extra_steps_ad_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/editor_ad_bypass_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/prop_inventory_persistence_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/prop_system_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/web_ad_shell_smoke.gd`
- Browser verification at `http://localhost:5174/`: hint prop ad opened Google “Rewarded ad example” directly without the custom “观看广告” prompt; after the rewarded countdown and close action, console logged `adViewed` and `rewarded completed` with the matching one-shot request id.
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/available_step_end_state_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/settings_menu_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/start_menu_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script test/button_click_sfx_scope_smoke.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-debug "Android Debug" builds/android/Word\ Solitaire-admob-test.apk`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Web" builds/web/index.html`
- `git diff --check`

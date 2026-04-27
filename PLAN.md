# Plan

## Main Build

- [x] Capture confirmed game rules in `docs/game_rules.md`.
- [x] Build a playable Godot 2D prototype with four areas.
- [x] Implement draw pile, wash-back, click-to-move, collection, steps, win, and fail states.
- [x] Validate the project with Godot headless/editor run.
- [x] Capture a screenshot for visual verification.

## Verification Criteria

- [x] Project opens and runs `res://scenes/main.tscn` without script errors.
- [x] The screen shows areas 1, 2, 3, and 4 in a vertical mobile layout.
- [x] Clicking the deck draws cards into area 1 and consumes steps.
- [x] When the deck is empty, clicking it washes area 1 back into area 2 and consumes steps.
- [x] Category cards can enter area 3 and then absorb matching word cards.
- [x] Same-category word groups in area 4 move together.
- [x] Clearing all cards and categories wins; running out of steps before clearing fails.

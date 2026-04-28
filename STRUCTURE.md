# Godot Demo

完整逻辑文件树见 [`docs/file_structure.md`](docs/file_structure.md)。

## Dimension

2D mobile portrait UI.

## Scenes

### Main

- **File:** `res://scenes/main.tscn`
- **Root type:** `Control`
- **Script:** `res://scripts/main.gd`
- **Purpose:** Owns live game state, drag interactions, rendering, animation handoffs, round transitions, and win/fail checks.

## Scripts

### Main

- **File:** `res://scripts/main.gd`
- **Extends:** `Control`
- **Responsibilities:**
  - Loads the category library used by round generation.
  - Creates an initial deck and four board columns.
  - Renders the four gameplay areas.
  - Handles deck draw and wash-back.
  - Handles drag source detection and legal target placement.
  - Absorbs words into category cards in area 3.
  - Reveals covered cards in area 4 after lower cards move away.
  - Tracks remaining steps and win/fail states.
  - Delegates category selection, solving, and audio playback to helper scripts.

### CategoryLibrary

- **File:** `res://scripts/category_library.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Stores the full category and word library.
  - Provides a copy of the library to `main.gd` so runtime selection can safely mutate dictionaries.
  - Stores manual conflict groups for categories that should not appear in the same round.
  - Keeps large content edits out of the main scene script.

### CategorySelector

- **File:** `res://scripts/category_selector.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Randomly selects the category subset for a round.
  - Generates fixed 3-8 word-count slots for each round, then samples words from categories that can satisfy those slots.
  - Enforces long-category difficulty caps.
  - Keeps word-count lengths varied when possible.
  - Rejects cross-category conflict tokens such as `茶几` and `茶盘` appearing in the same round.

### DealSolver

- **File:** `res://scripts/deal_solver.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Converts the live deal into compact card-id state.
  - Runs randomized DFS samples to verify the deal is solvable.
  - Estimates solution length for the displayed step budget.
  - Keeps solver heuristics separate from UI and animation code.

### GameAudio

- **File:** `res://scripts/game_audio.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Creates looping BGM and pooled SFX players.
  - Applies base-plus-trim volume balancing.
  - Mirrors public audio fields back to `main.gd` for smoke tests and diagnostics.

## Input

- Mouse/touch press on cards, category slots, empty board columns, and deck button.
- Drag starts after the pointer crosses the drag threshold.
- Releasing over a legal category slot or board column performs the move.
- Clicking/tapping the deck draws a card or washes the open pile back into the deck.

## Assets

- Audio assets live under `res://assets/audio`.
- UI uses generated Godot controls, colors, and text.

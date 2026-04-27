# Godot Demo

## Dimension

2D mobile portrait UI.

## Scenes

### Main

- **File:** `res://scenes/main.tscn`
- **Root type:** `Control`
- **Script:** `res://scripts/main.gd`
- **Purpose:** Owns level data, card state, click-to-move interactions, rendering, and win/fail checks.

## Scripts

### Main

- **File:** `res://scripts/main.gd`
- **Extends:** `Control`
- **Responsibilities:**
  - Defines category and word card data.
  - Creates an initial deck and four board columns.
  - Renders the four gameplay areas.
  - Handles deck draw and wash-back.
  - Handles click selection and legal target placement.
  - Absorbs words into category cards in area 3.
  - Reveals covered cards in area 4 after lower cards move away.
  - Tracks remaining steps and win/fail states.

## Input

- Mouse/touch press on cards, category slots, empty board columns, and deck button.
- First click selects a legal source.
- Second click chooses a legal target.

## Assets

- No external gameplay assets in the first prototype.
- UI uses generated Godot controls, colors, and text.

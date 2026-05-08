# Word Solitaire

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
  - Positions gameplay in a centered 720-wide safe-area design frame for tall and wide mobile screens.
  - Listens for runtime viewport resize events and re-renders layout without rebuilding the current deal.
  - Handles deck draw and wash-back.
  - Handles drag source detection and legal target placement.
  - Absorbs words into category cards in area 3.
  - Reveals covered cards in area 4 after lower cards move away.
  - Tracks remaining steps and win/fail states.
  - Renders hint/undo prop buttons, ad badges, and the step-out “增加步数” rewarded-ad action.
  - Delegates category selection, solving, audio playback, ad routing, and prop inventory logic to helper scripts.

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
  - Respects the music/SFX toggles persisted by `main.gd`.
  - Mirrors public audio fields back to `main.gd` for smoke tests and diagnostics.

### PropSystem

- **File:** `res://scripts/prop_system.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Stores permanent hint/undo inventory.
  - Resets per-round undo history and active hint state without resetting inventory.
  - Finds the next legal hint action.
  - Records and restores undo snapshots.
  - Exposes ad eligibility checks for zero-inventory hint/undo use.

### AdService

- **File:** `res://scripts/ads/ad_service.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Provides the single rewarded-ad entrypoint used by `main.gd`.
  - Emits reward/failure signals instead of mutating game state directly.
  - Routes debug/editor bypass requests to `DebugAdProvider`.
  - Routes Web exports to `WebAdProvider` when the custom HTML shell exposes the JS bridge.
  - Routes Android/iOS runtime requests to `AdmobProvider` when the native singleton is available.

### WebAdProvider

- **File:** `res://scripts/ads/web_ad_provider.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Calls the `WordSolitaireWebAds` bridge injected by `web/shell.html`.
  - Uses Google H5 Ad Placement API rewarded placements for Vercel/self-hosted Web exports.
  - Requests `preloadAdBreaks: "on"` before the first ad break and reports availability only after Google `onReady`.
  - Sends a one-shot `requestId` with each rewarded request and ignores callback ids that do not match the current pending request.
  - Calls Google-provided `showAdFn()` directly from the rewarded flow so the prop button opens the official mock ad without an extra custom prompt.
  - Keeps the old local test-ad overlay as an explicit fallback path, but it is disabled by default so it does not mask Google mock-ad failures.
  - Freezes the public JS bridge object after initialization, leaving only the minimal request/availability API exposed.
  - Grants rewards only after the JS bridge reports a viewed rewarded ad.
  - Keeps desktop and editor runs quiet by only touching `JavaScriptBridge` on Web exports.

### AdmobProvider

- **File:** `res://scripts/ads/admob_provider.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Dynamically creates the plugin `Admob` node only on Android/iOS when `AdmobPlugin` singleton exists.
  - Initializes the Google Mobile Ads SDK through the Godot AdMob plugin.
  - Preloads rewarded ads and shows them for hint, undo, and extra-step placements.
  - Grants rewards only after the SDK emits `rewarded_ad_user_earned_reward`, then waits for dismissal before resuming gameplay input.
  - Reads AdMob app/ad-unit IDs from the `admob/*` project settings; current defaults are Google test IDs.

### DebugAdProvider

- **File:** `res://scripts/ads/debug_ad_provider.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Simulates rewarded-ad success when `ad_bypass` export feature is present.
  - Simulates rewarded-ad success by default in Godot editor runs.
  - Keeps bypass state runtime-only; it is not persisted in user settings.

### AdResult

- **File:** `res://scripts/ads/ad_result.gd`
- **Extends:** `RefCounted`
- **Responsibilities:**
  - Holds stable business-level ad result constants for future provider adapters.

## Input

- Mouse/touch press on cards, category slots, empty board columns, and deck button.
- Drag starts after the pointer crosses the drag threshold.
- Releasing over a legal category slot or board column performs the move.
- Clicking/tapping the deck draws a card or washes the open pile back into the deck.
- In Godot editor runs, rewarded-ad bypass is enabled by default.

## Persistence

- Audio toggles, tutorial completion, and permanent prop inventory are stored in `user://settings.cfg`.
- Hint/undo inventory lives under the `props` section.
- The editor ad bypass state is intentionally not persisted.
- AdMob SDK IDs live in `project.godot` under `[admob]` and in `addons/AdmobPlugin/android_export.cfg` / `ios_export.cfg` for export-time App ID injection.
- Web H5 ads are configured in `web/shell.html`; the first version uses Google test mode by default and needs a real H5 Ads client ID before production monetization.

## Assets

- Audio assets live under `res://assets/audio`.
- UI uses generated Godot controls, colors, and text.
- Ad UI uses `res://assets/ui/ad_play.svg` for rewarded-ad badges and the extra-steps action.
- The native AdMob plugin lives under `res://addons/AdmobPlugin`; iOS embedded SDK frameworks live under `res://ios/framework`.
- Web export uses `res://web/shell.html` to load the Godot canvas, boot loader, and Google H5 rewarded-ad bridge in one document.

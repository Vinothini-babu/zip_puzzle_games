# ZIP – Cozy cartoon theme kit

## What's new in this update
- **Real playable board** (`game/zip_puzzle_generator.dart` + `widgets/zip_puzzle_grid.dart`):
  randomised Hamiltonian-path generator + drag-to-connect grid with real-time
  checkpoint order validation (correct = teal fill, wrong = red flash, drag
  back to undo). No demo buttons anymore.
- **HOW TO PLAY**: auto-shows once, the very first time Level 1 opens
  (tracked in `GameState.seenHowToPlay`, persisted). A small HOW TO PLAY
  button also stays on screen on Level 1 so the player can reopen it.
- **Non-spoiler level cards**: `mini_board_preview.dart` now draws a blank
  board with a zip-bolt badge instead of showing the full solved path.
- **Level Complete replay**: `widgets/solved_grid_preview.dart` draws the
  player's own winning path into the hoop, cell by cell.

If you already have your own `zip_puzzle_generator.dart` / `zip_puzzle_grid.dart`
with the Hamiltonian backtracking you mentioned, you can swap these out —
just keep the same `ZipPuzzle` shape (`n`, `path`, `checkpointOf`) and the
`onSolved(path)` callback so the rest of the app (board_factory, level
complete, hint) keeps working unchanged.

## Install
1. Copy the `lib/` folders into your project (`core/`, `widgets/`, `screens/`, `game/`).
   `lib/main.dart` replaces yours (keep your Firebase init line inside it).
2. Add the two packages from `pubspec_additions.yaml`, then `flutter pub get`.
3. Old screens (splash, level_select, level_complete, shop, puzzle_screen, app_state)
   are replaced by the new ones. Keep `zip_puzzle_generator.dart`,
   `zip_puzzle_grid.dart`, `solved_grid_preview.dart`, `level_data.dart`.

## Plug in your real grid (one file)
Open `lib/game/board_factory.dart` and return your `ZipPuzzleGrid` instead of `DemoBoard`.

Your grid must call:
- `controller.reportReset()`   when the player cleans/breaks the path  (uses up a MOVE)
- `controller.reportSolved()`  when the puzzle is solved

Optional:
- `controller.showHint = () {...}`                    hint button (costs coins)
- `controller.solvedPreviewBuilder = (_) => SolvedGridPreview(...)`  shown in the hoop

## Tune the game
`lib/core/app_theme.dart` -> `AppInfo` (studio name, price, moves per level, hint cost, ...)
and `AppColors` (theme). Reward formula: `_computeReward()` in `puzzle_screen.dart`.

## Stubs to replace before release
- `core/ad_service.dart`  -> google_mobile_ads rewarded ads
- shop purchases          -> in_app_purchase
- `core/game_state.dart`  -> shared_preferences now; add Firebase sync if you want cloud save

# Feature 005b — Multi-Player Round Screen Redesign

## Goal
Replace the sequential one-player-at-a-time UX with a simultaneous view showing all players in rows, so the group can see everyone's status at a glance.

## Requirements
- Round screen shows ALL players in a list for the current hole
- Each player row displays:
  - Player name
  - Score for this hole (blank/— if not yet entered)
  - Filled black dot (●) if the player receives a handicap stroke on this hole
- Tapping a player row expands it to show the score entry grid (1–9 buttons)
- Only one row expanded at a time; tapping another player collapses the previous
- First un-scored player on a hole is auto-expanded by default
- Scoring a player collapses their row and auto-expands the next un-scored player
- When all players have scored the hole, advance to next hole automatically
- Past holes (back-navigation) retain the existing "tap to re-edit" behaviour

## Handicap Stroke Indicator
- Uses a per-hole stroke index (1 = hardest, 18 = easiest)
- Player receives a stroke on a hole if `holeStrokeIndex <= player.handicap`
- Dot is always ● (filled circle); shown even if score not yet entered
- Default stroke index hardcoded in `Course.defaultStrokeIndex` until course DB exists

## Accessibility Identifiers
- `round.playerRow.<playerID>` — the tappable row for each player
- `round.scoreButton.<n>` — unchanged (score grid buttons 1–9)
- `round.holeLabel`, `round.parLabel`, `round.prevHoleButton`, `round.nextHoleButton` — unchanged

## Data changes
- `AppState.recordScore` no longer cycles `currentPlayerIndex`; instead checks if all players have scored the hole → advance `currentHole`
- `currentPlayerIndex` and `currentPlayer` removed from AppState (view manages active player locally)

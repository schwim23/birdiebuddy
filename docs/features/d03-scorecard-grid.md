# Feature D03 — Scorecard Landscape Full-Grid View

## Goal
Show a traditional 18-hole paper-style scorecard accessible from the round screen.

## Access
Toolbar button ("Scorecard") on RoundView pushes ScorecardView via AppRouter.

## Layout
Horizontally scrollable grid (ScrollView .horizontal):

| Column   | Width | Content                        |
|----------|-------|--------------------------------|
| Label    | 72pt  | "Par" / player names           |
| Holes 1–9| 36pt  | score or "–"                   |
| OUT      | 48pt  | front-9 total                  |
| Holes 10–18 | 36pt | score or "–"                  |
| IN       | 48pt  | back-9 total                   |
| TOT      | 48pt  | 18-hole total                  |

Row order:
1. Hole numbers header row
2. Par row
3. One row per player

## Score cell colors (matching D02 palette)
- Eagle+: Sand Trap Gold `#F9A825`
- Birdie:  Emerald Green `#2E7D32`
- Par:     no fill (neutral)
- Bogey:   Rough Red `#C62828`
- Double+: Dark Red `#8B0000`
- Unplayed: "–" in secondary color, no fill

## Navigation
- Add `.scorecard` to AppRoute enum
- Add `ScorecardView()` to BirdieBuddyApp navigationDestination
- Add toolbar .principal or .topBarTrailing button in RoundView: "Scorecard" with `list.bullet` icon
- Scorecard has a back button (standard nav back)

## Accessibility Identifiers
- `scorecard.grid` — the outermost scroll container
- `scorecard.cell.\(playerName).\(hole)` — each score cell

## Also in this PR: Hole-Forward Navigation Fix
- Bug: tapping "›" in RoundView is disabled for holes not yet played
- Fix: change `canGoForward` from `displayHole < appState.currentHole`
  to `displayHole < 18` so you can navigate to any hole 1–18
- Entering a score on a future hole still works — `recordScore` already handles out-of-order entries

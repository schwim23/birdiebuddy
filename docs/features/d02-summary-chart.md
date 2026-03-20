# Feature D02 — Round Summary Scoring Profile Chart

## Goal
Enrich the post-round SummaryView with a visual scoring profile showing how many
eagles, birdies, pars, bogeys, and doubles (or worse) each player made.

## Layout (appended below existing score display)
1. Section header: "Scoring Breakdown"
2. One row per player (single-player rounds: one row)
   - Player name label (hidden for single player)
   - Colored pill segments proportional to hole count
   - Legend row: counts per category

## Score categories
| Category | Relative to par | Color          |
|----------|----------------|----------------|
| Eagle+   | ≤ −2           | Sand Trap Gold `#F9A825` |
| Birdie   | −1             | Emerald Green  `#2E7D32` |
| Par      | 0              | Fairway Gray   `#757575` |
| Bogey    | +1             | Rough Red      `#C62828` |
| Double+  | ≥ +2           | Dark Red       `#8B0000` |

## Data
- Par per hole: `Course.defaultPar` (all 4s until D04 course setup)
- Scores: `appState.scores[player.id][hole]` for holes 1–18
- Only holes the player completed are included in the chart

## Accessibility Identifiers
- `summary.scoringBreakdown` — the VStack container
- `summary.breakdownBar.\(playerName)` — the colored bar for each player

## Notes
- Bar width proportional to (holesPlayed / 18)
- Minimum segment width: only render a segment if count > 0
- Hidden if no holes were played (edge case)

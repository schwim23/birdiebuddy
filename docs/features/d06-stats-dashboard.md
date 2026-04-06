# Feature D06 — Stats Dashboard

**Status:** Implemented

---

## Overview

A stats screen accessible from the home screen showing historical scoring statistics per player, computed from saved `RoundRecord` data. No external data required — all stats are derived from rounds already played and saved via SwiftData (Feature 006).

---

## Data Source

Stats are computed from `RoundRecord` instances stored in SwiftData. Each record contains:
- `playerNames: [String]`
- `scoreEntries: [ScoreEntry]` — playerName, hole, strokes
- `parData: Data?` — JSON-encoded `[Int: Int]` par per hole (added in D06; nil for pre-D06 records, falls back to all-4s default)
- `date: Date`

`RoundRecord` gains a new optional property `parData: Data?` so scoring breakdown (eagle/birdie/par/bogey) can be accurately computed from history. `SummaryView` is updated to persist `AppState.roundPar` when saving a round.

---

## Stats Shown

| Stat | Description |
|---|---|
| Rounds played | Count of rounds containing this player |
| Average score | Mean total strokes across all rounds |
| Best round | Lowest total strokes in a single round |
| Worst round | Highest total strokes in a single round |
| Scoring breakdown | Aggregate eagle/birdie/par/bogey/double+ counts across all rounds |
| Recent rounds | Last 10 rounds — date, total score, score vs par |

Driving accuracy and putting stats require per-shot data not currently tracked; deferred to a future spec.

---

## UI

### HomeView changes
- "Stats" button below the "Start New Round" button (only shown when at least one round has been saved)

### StatsView (new screen)
- Player picker (segmented or menu) when multiple `PlayerProfile` records exist — defaults to most recently played
- Overview card: rounds / avg score / best / worst
- Scoring breakdown bar — same colour-coded segment bar as `SummaryView`, but aggregated across all rounds
- Recent rounds list — last 10, with date, score, and score-relative-to-par indicator (green = under, red = over)

---

## AppRoute

```swift
case stats
```

---

## Accessibility Identifiers

- `home.statsButton`
- `stats.playerPicker`
- `stats.overviewCard`
- `stats.roundsCount`
- `stats.averageScore`
- `stats.bestRound`
- `stats.worstRound`
- `stats.breakdownBar`
- `stats.recentRoundRow`

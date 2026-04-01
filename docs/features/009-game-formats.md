# Feature 009 — Additional Game Formats

**Status:** Future (no blockers; Best Ball and Wolf need N-player match play foundation)

---

## Overview

Extends the `GameFormat` enum and scoring engine to support four new formats beyond stroke play and match play. Each format has distinct scoring rules, player groupings, and summary displays.

---

## Formats

### Best Ball (Four Ball)

Two teams of two. Each player plays their own ball; the team's score on each hole is the **better net score** of the two partners.

- Teams defined at setup (player 1+3 vs player 2+4, or user-assigned)
- Net score per player = gross − handicap strokes received on that hole (same allocation as match play: SI-based)
- Hole winner: team with the lower best-ball net score; halved if equal
- Running status mirrors match play: "Team A 2 UP", "All Square", "Dormie 1"
- Match ends early if one team clinches (same dormie/decided logic as 007)
- Summary: winning team, final score (e.g. "3&2"), per-hole breakdown

**Setup constraints:** Exactly 4 players required.

---

### Wolf

One player per hole is designated the "Wolf" (rotates each hole 1→2→3→4→1...). After each player tees off, the Wolf decides whether to partner with that player or go alone ("Lone Wolf").

**Point system (per hole):**
- Wolf + partner beat the other two: Wolf earns 2 pts, partner earns 1 pt, losers 0
- Wolf + partner lose: each opponent earns 2 pts, Wolf and partner 0
- Lone Wolf beats all three: Wolf earns 4 pts, others 0
- Lone Wolf loses: each opponent earns 2 pts, Wolf 0
- Halved hole: all players earn 1 pt (standard Wolf variant)

Net scores used for hole comparison (handicap strokes allocated by SI, same as match play).

**UI additions:**
- Round screen shows which player is Wolf on the current hole
- After all players tee off, Wolf chooses partner (or "Go Alone") before scores are entered
- Running point totals shown in match status banner

**Setup constraints:** Exactly 4 players required.

---

### 5-3-1 (also called 6-3-1 in some regions)

Each hole is worth 9 points total, distributed by finish position.

| Finish | Points |
|---|---|
| 1st (best net) | 5 |
| 2nd | 3 |
| 3rd | 1 |
| 4th (worst) | 0 |

Ties split the points for the tied positions evenly (e.g. two players tie for 1st: each gets (5+3)/2 = 4).

Running cumulative point totals replace match status text.

**Setup constraints:** Exactly 4 players required.

---

### Alternate Shot (Foursomes)

Two teams of two. Partners **alternate hitting the same ball**. One partner tees off on odd holes, the other on even holes. Scoring is by match play (holes won/lost/halved), net of one combined team handicap.

**Team handicap:** average of both partners' handicaps, rounded; strokes allocated by SI as usual.

**UI additions:**
- Round screen shows which partner is hitting this shot (alternates each stroke within a hole)
- Stroke counter per hole reflects combined team progress

**Setup constraints:** Exactly 4 players (2 teams of 2).

---

## Data Model Changes

```swift
enum GameFormat: String, CaseIterable, Codable {
    case strokePlay    = "Stroke Play"
    case matchPlay     = "Match Play"
    case bestBall      = "Best Ball"
    case wolf          = "Wolf"
    case fiveThreeOne  = "5-3-1"
    case alternateShot = "Alternate Shot"
}

// Wolf-specific per-hole state
struct WolfHoleState {
    let wolfPlayerID: UUID
    var partnerPlayerID: UUID?   // nil = Lone Wolf
    var isDecided: Bool          // true once Wolf has chosen
}
```

**`AppState` additions:**
- `wolfHoleStates: [Int: WolfHoleState]` — keyed by hole number
- `teamAssignments: [[UUID]]` — for Best Ball and Alternate Shot (array of 2 teams)
- `fiveThreeOnePoints: [UUID: Int]` — running totals for 5-3-1
- Format-specific scoring methods alongside existing match play methods

---

## UI Changes

| Screen | Change |
|---|---|
| `SetupView` | Format picker gains new options; team assignment UI for Best Ball/Alternate Shot; player count validation per format |
| `RoundView` | Wolf chooser overlay after tee shots; partner/solo indicators; format-appropriate status banner |
| `SummaryView` | Format-aware result: match score, point totals, or hole-by-hole breakdown |

---

## Accessibility Identifiers

- `setup.teamAssignment` — team picker for Best Ball / Alternate Shot
- `round.wolfPicker` — Wolf partner selection overlay
- `round.wolfIndicator` — label showing current hole's Wolf
- `summary.pointsTotals` — 5-3-1 final point breakdown

---

## Phased Delivery

| Phase | Formats |
|---|---|
| 1 | Best Ball — closest to existing match play engine |
| 2 | 5-3-1 — pure points, no match state needed |
| 3 | Wolf — per-hole decision UI is new interaction pattern |
| 4 | Alternate Shot — stroke-level alternation logic |

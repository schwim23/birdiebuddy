# Feature 007 — Match Play with Handicap-Stroke Scoring

## Goal
Add match play as a selectable game format alongside existing stroke play. Two players compete hole-by-hole on net scores, with handicap strokes allocated by the difference in their handicaps.

## Scope
- Two-player match play only (N-player match formats are future work)
- If more than 2 players are in setup, match play option is hidden
- All other multi-player rounds continue as stroke play

## Handicap Stroke Allocation
- Lower handicapper receives 0 strokes; higher handicapper receives (diff) strokes
- Strokes are given on the `diff` hardest holes (lowest stroke index ≤ diff)
- E.g., handicap 12 vs 20: Player B gets 8 strokes on holes with SI ≤ 8
- For diff > 18: 2 strokes on holes with SI ≤ (diff − 18), 1 stroke elsewhere

## Hole Scoring
- Net score = gross strokes − strokes received on that hole
- Hole winner: player with lower net score (halved if equal)
- Running match status: "Mike 3 UP", "All Square", "Jon 1 UP"
- Dormie: when lead equals holes remaining ("Dormie 2")
- Match decided early: when |lead| > holes remaining → navigate to summary immediately

## UI Changes
- **SetupView:** Segmented picker (Stroke Play / Match Play) — only shown for 2 players
- **RoundView:** Match status banner below hole header; handicap dots reflect match play allocation
- **SummaryView:** Prominent match result ("Mike wins 3&2", "Jon wins 1 UP", "Halved")

## Accessibility Identifiers
- `setup.formatPicker` — the game format picker
- `round.matchStatusLabel` — running match status text
- `summary.matchResultLabel` — final match play result

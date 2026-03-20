# Feature D01 — Home Screen Redesign

## Goal
Replace the minimal home screen with a rich dashboard matching the design.md spec:
handicap hero card, prominent Start Round CTA, and a recent-rounds list.

## Layout (top → bottom)
1. **Header** — app icon + "Birdie Buddy" wordmark
2. **Handicap card** — shows the most recently played PlayerProfile's name + handicap index
3. **Start New Round** — full-width, 56pt, Emerald Green primary button
4. **Recent Rounds** — last 3 RoundRecords (date, players, total scores per player)

## Data sources
- `@Query(sort: \RoundRecord.date, order: .reverse)` — most recent rounds first
- `@Query` PlayerProfiles sorted in-code by `lastPlayed` descending → first = primary profile

## Round row format
- Date: "Today" / "Yesterday" / "Mar 18"
- Single player: just the score
- Multi-player: first name + score per player on the right

## Handicap card
- Shows the saved handicap from the PlayerProfile (user-entered, not calculated)
- Calculated handicap from round history is a future feature
- Hidden if no profiles exist yet

## Accessibility Identifiers
- `home.startRoundButton` — unchanged (existing tests rely on this)
- `home.handicapCard`
- `home.recentRoundRow` (one per row)

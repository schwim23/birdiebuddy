# Feature 006 — SwiftData Persistence

## Goal
Save player profiles and completed rounds across app launches using SwiftData (iOS 17).

## Requirements
- Saved players persist across launches (replaces UserDefaults `SavedPlayersStore`)
- A completed round (all 18 holes scored) is automatically saved to history
- No manual save action required — SwiftData auto-saves
- Existing in-memory `AppState` + `Player` struct remain unchanged (SwiftData models are separate)

## SwiftData Models

### `PlayerProfile`
Persisted player profile for the saved-players list.
- `id: UUID`
- `name: String`
- `handicap: Int`
- `lastPlayed: Date?`
- `asPlayer: Player` — convenience converter

### `RoundRecord`
One completed 18-hole round.
- `id: UUID`
- `date: Date`
- `playerNames: [String]`
- `scoresData: Data` — JSON-encoded `[ScoreEntry]` (playerName + hole + strokes)

### `ScoreEntry` (Codable, not a model)
- `playerName: String`
- `hole: Int`
- `strokes: Int`

## Changes
- `BirdieBuddyApp` — `.modelContainer(for: [PlayerProfile.self, RoundRecord.self])`
- `SetupView` — replace `@Environment(SavedPlayersStore.self)` with `@Query` + `@Environment(\.modelContext)`
- `SummaryView` — insert `RoundRecord` via `modelContext` on `.onAppear` (guarded against double-save)
- Delete `Services/SavedPlayersStore.swift`

## Migration
UserDefaults saved-player data is not migrated. This is a dev-phase app; the UserDefaults key will be silently ignored.

## Accessibility Identifiers
No changes.

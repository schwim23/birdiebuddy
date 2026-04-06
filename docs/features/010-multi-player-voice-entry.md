# Feature 010 — Multi-Player Voice Score Entry

**Status:** Future (no blockers; builds on existing ScoreParser + SpeechRecognizer)

---

## Overview

Currently, voice score entry works one player at a time — the user taps a player's row, speaks a score, and the field fills in. This feature allows the user to dictate all players' scores for a hole in a **single utterance**, e.g.:

> "Joe got a five, Mike had a bogey, Dan made par, Josh shot a six"

The app parses each segment, matches it to a player by name, and fills all scores simultaneously.

---

## Example Utterances

| Input | Players scored |
|---|---|
| `"joe five, mike bogey, dan par, josh six"` | All 4 in one go |
| `"mike birdie dan bogey"` | 2 players; others left blank |
| `"everyone made par"` | All players assigned par for current hole |
| `"joe and dan made bogey, mike and josh had par"` | Group assignment |
| `"joe five mike four dan six"` | No punctuation — name-then-score pairs |

---

## Parser Design

### New parser: `MultiScoreParser`

Separates the utterance into **player-score segments**, then applies existing `ScoreParser` to each score fragment.

**Step 1 — Segment splitting:**
Split on commas and connector phrases (`" and "`, `" then "`, `" also "`). Each segment is expected to contain one player reference and one score.

**Step 2 — Player name matching:**
For each segment, fuzzy-match the first token(s) against the current round's player names (case-insensitive, first-name match sufficient). Unmatched segments are ignored.

**Step 3 — Score extraction:**
Pass the remainder of the segment to `ScoreParser.parse(_:par:)` using the current hole's par.

**Step 4 — Special phrases:**
- `"everyone made par"` / `"all par"` → assign par to all players
- `"everyone bogey"` → assign bogey to all players
- `"[name1] and [name2] had bogey"` → assign same score to named players

```swift
enum MultiScoreParser {
    struct ParsedScore {
        let playerName: String   // matched player name (original casing)
        let strokes: Int
    }

    /// Parses a multi-player utterance. Returns only segments that matched a known player.
    static func parse(_ text: String, players: [Player], par: Int) -> [ParsedScore]
}
```

---

## Voice Session Changes

### New listening mode: `.multiScore`

Alongside existing `.score` (single player) and `.text` (free text), add a mode that:
- Uses `ScoreParser.contextualStrings` + all current player first names as contextual hints
- Waits for a longer silence timeout (15s vs 10s for single score) to allow full utterance
- On result, calls `MultiScoreParser.parse()` and fills all matched scores

```swift
// SpeechRecognizer addition
func startListeningForMultiScore(players: [Player], par: Int, onScores: @escaping @MainActor ([MultiScoreParser.ParsedScore]) -> Void)
```

---

## UI Changes

### RoundView

- Replace per-player microphone button with a single **"Dictate All"** button at the top of the hole section
- Tapping it starts the multi-score listening session
- While listening: the button pulses and shows "Listening..."
- After parsing: fills each matched player's score field and highlights any unmatched players so the user can fill them manually
- Existing per-player mic buttons remain for individual correction

### Confirmation step (optional, Phase 2)

Before committing scores, show a brief confirmation overlay:
```
Joe    → 5  ✓
Mike   → 5  (bogey) ✓
Dan    → 4  (par) ✓
Josh   → 6  ✓
```
User taps "Confirm" or edits inline.

---

## Accessibility Identifiers

- `round.dictateAllButton` — the "Dictate All" mic button
- `round.multiScoreConfirmation` — confirmation overlay (Phase 2)

---

## Data Model Changes

None. `AppState.recordScore()` is called once per matched player, same as today.

---

## Phased Delivery

**Phase 1:**
- `MultiScoreParser` with comma/connector splitting and player name fuzzy match
- `startListeningForMultiScore` on `SpeechRecognizer`
- "Dictate All" button fills scores directly (no confirmation step)
- "everyone made par/bogey" special phrases

**Phase 2:**
- Confirmation overlay before committing
- Group assignment ("Joe and Dan had bogey")
- Improved fuzzy matching (nickname support, e.g. "J" for Joe)

---

## Test Coverage

New unit tests in `BirdieBuddyTests/MultiScoreParserTests.swift`:
- Single player in utterance
- All players comma-separated
- "everyone par" / "everyone bogey"
- Unrecognised player name ignored
- Partial match (2 of 4 players named)
- Mixed golf terms and digits in same utterance
- Case insensitivity and leading/trailing whitespace

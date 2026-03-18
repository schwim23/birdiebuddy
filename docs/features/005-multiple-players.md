# Feature 005 — Multiple Players & Handicaps

## Goal
A round can include multiple players, each with a handicap index. Players can be saved and reused across rounds.

## Requirements
- Setup screen before the round: add players by name + handicap (0–54)
- Voice input on setup: "add joe chanley he is a 12 handicap, mike s who is a 14, dan who is a 8 and josh who is a 9"
  - Parses multiple players from one utterance (comma or "and" separated)
  - Accepts: number words, digits, golf terms (scratch = 0)
- Saved players: any player added to a round is auto-saved; reusable in future rounds
- Saved player handicap can be overridden at round-start without changing the saved value
- Round screen cycles through all players per hole (Player 1 scores, then Player 2, etc.)
- Reviewing past holes shows all players' scores; any can be re-edited
- Summary shows each player's total, sorted by score ascending

## Accessibility Identifiers
- `setup.playerNameField`
- `setup.handicapStepper`
- `setup.addPlayerConfirmButton`
- `setup.startRoundButton`
- `setup.micButton`
- `setup.voiceFeedbackLabel`
- `round.playerLabel`
- `summary.playerRow` (one per player)

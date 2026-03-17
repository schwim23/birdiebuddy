# Feature 004 — Voice Score Entry

## Goal
The user can speak their score for the current hole instead of tapping a button.

## Requirements
- A microphone button appears on the round screen
- Tapping it starts listening for a spoken score
- Recognized score (1–9) is recorded and the app advances to the next hole
- Spoken number words ("five") and digits ("5") are both accepted
- Golf terms are accepted: birdie, bogey, par, eagle, double, triple, ace
- A feedback label shows what was heard (e.g. "Heard: five → 5")
- If permission is denied or microphone unavailable, the button is hidden; tap buttons still work
- Listening stops automatically once a valid score is recognized

## Not in Scope
- UI automation tests for voice (microphone unavailable in simulator)
- Handicap adjustments (future feature)

## Accessibility Identifiers
- `round.micButton` — microphone toggle button
- `round.voiceFeedbackLabel` — label showing what was heard

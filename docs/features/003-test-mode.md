# Feature 003 — Test Mode

## Goal
The app supports deterministic UI automation.

## Requirements
- Stable accessibility identifiers on all interactive controls
- App can launch in test mode with no blocking prompts
- No onboarding flows in MVP

## Accessibility Identifiers
- home.startRoundButton
- round.holeLabel
- round.parLabel
- round.scoreButton.3
- round.scoreButton.4
- round.scoreButton.5
- round.scoreButton.6
- round.scoreButton.7
- round.scoreButton.8
- round.scoreButton.9
- round.scoreButton.10
- round.currentScoreLabel
- summary.totalScoreLabel

## Acceptance Criteria
- UI tests can reliably find and tap all controls by identifier

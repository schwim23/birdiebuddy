# Birdie Buddy — Roadmap

Features are listed in rough priority order. Each gets a feature spec in docs/features/ before implementation.

## Completed

### Core scoring
- [x] 001 — Start round
- [x] 002 — Enter score (tap buttons 1–9)
- [x] 003 — UI test mode (accessibility identifiers)
- [x] 004 — Voice score entry (SFSpeechRecognizer, ScoreParser, phonetic aliases)
- [x] 005 — Multiple players + handicaps + saved players + voice setup
- [x] 005b — Round screen redesign (simultaneous player rows w/ stroke dot)
- [x] 006 — SwiftData persistence (saved players + round history)
- [x] 007 — Match play with handicap-stroke scoring
- [x] 009 — Game formats: Best Ball, 5-3-1, Wolf, Alternate Shot
- [x] 010 — Multi-player voice score entry in one utterance
- [x] 011 — Course database (search, favorites, tee selection)

### Design & branding
- [x] D01 — Home screen redesign (handicap card + recent rounds)
- [x] D02 — Round summary scoring profile chart
- [x] D03 — Scorecard landscape full-grid view
- [x] D04 — Course setup screen (par + stroke index per hole)
- [x] D04b — Scorecard photo scanner (auto-fill course setup)
- [x] D06 — Stats dashboard (scoring breakdown, averages, recent rounds)

## Next Up — Collaborative rounds arc

Goal: pre-scheduled multi-player rounds with live scoreboards, backed by CloudKit.

- [ ] **D08** — Auth (Sign in with Apple + email) — see docs/features/d08-auth.md
- [ ] **D10** — CloudKit setup (container, record types, subscriptions) — see docs/features/d10-cloudkit-setup.md
- [ ] **013** — Collaborative rounds (pre-scheduled rounds, join codes, sync) — see docs/features/013-collaborative-rounds.md
- [ ] **008** — Live scoreboards (in-app live leaderboard for collab rounds) — see docs/features/008-live-scoreboards.md

## Other planned features

### Design & branding
- [ ] **D05** — Club bag setup screen
- [ ] **D07** — GPS rangefinder (CoreLocation yardage to green)
- [ ] **D09** — Buddy feed + group tournament

### Social & media
- [ ] 012 — Shot video clips (capture + share) — see docs/features/012-shot-video.md
- [ ] 014 — Events (multi-round tournaments) — see docs/features/014-events.md

## Backlog

### Players & handicaps
- [ ] Pull handicap index from GHIN API automatically
- [ ] Saved player profiles carry historical handicap forward

### Persistence
- [ ] Round history search/filter

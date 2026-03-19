# Birdie Buddy — Roadmap

Features are listed in rough priority order. Each gets a feature spec in docs/features/ before implementation.

## Completed
- [x] 001 — Start round
- [x] 002 — Enter score (tap buttons 1–9)
- [x] 003 — UI test mode (accessibility identifiers)
- [x] 004 — Voice score entry (SFSpeechRecognizer, ScoreParser, phonetic aliases)
- [x] 005 — Multiple players + handicaps + saved players + voice setup

## Next Up (in order)
- [ ] 006 — SwiftData persistence (save rounds across launches)
- [ ] 007 — Match play with handicap-stroke scoring

## Design & Branding
See `docs/design.md` for the full app specification, design system, and screen implementation priority.

- [ ] **D01** — Home screen redesign (recent rounds + handicap hero card) per design.md §7 Tier 1
- [ ] **D02** — Round summary scoring profile chart (birdies/pars/bogeys)
- [ ] **D03** — Scorecard landscape full-grid view
- [ ] **D04** — Course setup screen (par/stroke-index/slope per hole)
- [ ] **D05** — Club bag setup screen
- [ ] **D06** — Stats dashboard (driving accuracy, putting, scoring distribution)
- [ ] **D07** — GPS rangefinder (CoreLocation yardage to green)
- [ ] **D08** — Auth (Sign in with Apple + email)
- [ ] **D09** — Buddy feed + group tournament

## Backlog

### UX — Multi-Player Round Screen (005 follow-up)
- [ ] Redesign round screen: show ALL players in a row simultaneously instead of
      cycling one at a time
  - Each player row shows: name, score for current hole (empty if not yet entered),
    and a filled black dot (●) if that player receives a handicap stroke on the
    current hole (based on hole stroke index vs player handicap)
  - Tapping a player's row opens score entry for that player
  - Requires hole stroke index data (1–18 difficulty ranking per hole)
  - Voice entry: "Joe got a five, Mike had a bogey, Dan made par, Josh shot a six"
    — parse all in one utterance and fill the row

### Players & Handicaps
- [ ] Match play with handicap-stroke-based scoring
  - Strokes given per hole based on handicap differential and course slope/rating
  - Future: pull handicap index from GHIN API automatically
  - Future: saved player profiles carry their handicap forward

### Game Formats
- [ ] Match Play (with and without handicaps)
- [ ] Best Ball / Four Ball
- [ ] Wolf
- [ ] 5-3-1
- [ ] Alternate Shot (Foursomes)

### Persistence & Data
- [ ] Saved player profiles with historical rounds
- [ ] Round history view on home screen

### Courses
- [ ] Course database with real hole pars, yardages, and stroke indexes
- [ ] Slope rating + course rating for handicap calculation
- [ ] Scorecard photo scanning for course config

### Social
- [ ] Shot / round sharing
- [ ] Video highlights

### Advanced Voice
- [ ] Voice commands for navigation ("next hole", "go back")
- [ ] Multi-player score entry in one utterance on round screen

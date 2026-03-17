# Birdie Buddy — Roadmap

Features are listed in rough priority order. Each gets a feature spec in docs/features/ before implementation.

## In Progress
- [ ] 004 — Voice score entry

## Backlog

### Persistence
- [ ] SwiftData: save rounds across app launches
- [ ] Saved player profiles (name, handicap)

### Players & Handicaps
- [ ] Multiple players per round (manual entry)
- [ ] Per-player handicap (manually entered for now)
- [ ] Match play with handicap-stroke-based scoring
  - Each player needs a handicap index
  - Strokes given per hole based on handicap differential and course slope/rating
  - Future: pull handicap index from GHIN API automatically
  - Future: saved player profiles carry their handicap forward

### Game Formats
- [ ] Match Play (with and without handicaps)
- [ ] Best Ball / Four Ball
- [ ] Wolf
- [ ] 5-3-1
- [ ] Alternate Shot (Foursomes)

### Courses
- [ ] Course database with real hole pars and yardages
- [ ] Slope rating + course rating for handicap calculation
- [ ] Scorecard photo scanning for course config

### Social
- [ ] Shot / round sharing
- [ ] Video highlights

### Advanced Voice
- [ ] Voice entry for player name selection at round start
- [ ] Voice commands for navigation ("next hole", "go back")

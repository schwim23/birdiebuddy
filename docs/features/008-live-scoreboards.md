# Feature 008 — Pre-Scheduled Matches & Live Scoreboards

**Status:** Future (requires D08 — Auth + D10 — Hosting & Permissions, both undesigned)

---

## Overview

A "Match Room" is created before the round starts. The creator shares a 6-character code (e.g. `X4K9PQ`) or invite link. Players join in-app; spectators view via web URL `birdiebuddy.app/live/{CODE}`. Scores sync live as each player enters them on their own device. All existing formats are supported (stroke play, match play with handicaps).

---

## User Stories

1. **Creator (pre-round):** Opens app → "Start Live Match" → picks format + players + handicaps + optional tee time → gets a shareable code + link.
2. **Joining player:** Taps invite link or enters code → sees live scoreboard → when round starts, their round is automatically linked to the room.
3. **Spectator (web):** Opens `birdiebuddy.app/live/X4K9PQ` → sees live scoreboard, refreshes every 5s, no app required.
4. **In-round:** Each player's score entry pushes immediately to the room. Live scoreboard shows all players' running totals, match status, and per-hole breakdown.

---

## New App Screens

| Screen | Route | Description |
|---|---|---|
| `MatchLobbyView` | `.matchLobby` | Create or join a match room |
| `LiveScoreboardView` | `.liveScoreboard(code:)` | Full scoreboard with live updates, read-only or in-round |

**HomeView changes:** Add "Live Match" button alongside "New Round".

**Deep link handling in `BirdieBuddyApp`:** `.onOpenURL` parses `birdiebuddy://live/{CODE}` and `https://birdiebuddy.app/live/{CODE}` → navigates to `.liveScoreboard(code:)`.

---

## Data Model Additions

```swift
// New local model (in-memory, later synced to backend)
struct LiveMatch: Codable {
    let code: String                    // 6-char alphanumeric, server-generated
    let format: GameFormat
    let players: [LivePlayer]
    let courseSnapshot: CourseSnapshot? // par/strokeIndex per hole
    let scheduledTeeTime: Date?
    var scores: [String: [Int: Int]]    // playerName → hole → strokes
    var status: MatchStatus             // .scheduled / .active / .completed
    var createdAt: Date
}

enum MatchStatus: String, Codable {
    case scheduled   // created, not started
    case active      // in progress (first score entered)
    case completed   // all 18 holes done (or match play concluded)
}

struct LivePlayer: Codable {
    let name: String
    let handicap: Int
}
```

**`RoundRecord` additions (SwiftData migration):**
- `matchCode: String?` — links a saved round to a live room
- `isLive: Bool` — round was played in a live room

**`AppRoute` additions:**
```swift
case matchLobby
case liveScoreboard(code: String)
```

**`AppState` additions:**
- `currentMatchCode: String?` — set when round is started from a live room
- `recordScore()` — after local update, fire async push to backend (no-op if `currentMatchCode == nil`)

---

## Backend Requirements

New infrastructure — none of this exists in the current MVP. **Hosting, domain, and permissions model all require separate design (see D10).**

| Component | Description |
|---|---|
| REST API | `POST /rooms` (create), `GET /rooms/{code}` (lookup + scores), `PATCH /rooms/{code}/scores` (push score update) |
| Short code generation | 6-char alphanumeric, collision-checked, server-side |
| Auth | Creator requires Sign in with Apple (D08 prereq); viewer access governed by D10 permissions model |
| Live sync | Polling (5s intervals) for MVP; WebSocket push in Phase 2 |
| Hosting | **TBD — requires D10 design** (domain, infrastructure, CDN, web frontend hosting all undefined) |
| Web frontend | Served from TBD domain — HTML/CSS, JS polling; URL scheme TBD pending domain decision |

---

## Web Scoreboard

> **Domain and URL scheme are TBD.** No hosting platform, registered domain, or web infrastructure exists yet. This must be designed as part of D10 before any URL format is finalized.

The scoreboard page (at whatever URL is decided) will:
- Show player names, hole-by-hole scores, running total/net, match status (`Mike 2 UP`, `All Square`)
- Be format-aware: stroke play shows gross vs net; match play shows holes-up running status
- Auto-refresh every 5 seconds via `fetch` polling
- Show an "Open in App" banner on iOS with a deep link back to the app
- Handle all match types as additional formats are added (Best Ball, Wolf, etc.)

---

## Permissions Model (TBD — D10)

Access control for match rooms needs a full design pass. Open questions:

**Room-level visibility:**
- Public (anyone with the code can view scores)
- Private (only invited players can view)
- Group-restricted (only members of a defined group/club can view)

**User-level roles within a room:**
- Creator — can edit room config, cancel match, manage players
- Player — can enter their own scores, see full scoreboard
- Spectator — read-only, no score entry

**Group/club level:**
- Groups of users (e.g. a regular Saturday foursome, a club)
- Group admin can create rooms scoped to the group
- Group members can see all matches within the group
- Private groups vs open groups

**Auth:**
- Creators and players require authentication (D08 — Sign in with Apple)
- Spectators: public rooms viewable without auth; private rooms require invite token or account

All of the above is **undesigned**. Feature 008 cannot be fully specced until D10 defines the permissions model.

---

## Format Support Matrix

| Format | Live Scoreboard Shows | Match Status |
|---|---|---|
| Stroke Play | Gross score per hole, total gross, net total | Leaderboard by net score |
| Match Play | Per-hole W/L/H, running holes-up | `Mike 2 UP`, `Dormie 1`, final: `3&2` |
| Best Ball *(future)* | Best net score per hole per team | Team vs team holes-up |
| Wolf *(future)* | Per-hole team assignments + result | Running point totals |

---

## Prerequisites / Dependencies

| Prereq | Feature | Status |
|---|---|---|
| D08 — Auth | Sign in with Apple required for creator/player identity | Undesigned |
| D10 — Hosting & Permissions | Domain, infrastructure, web frontend, user/group permission model | **Undesigned — blocks 008** |
| Backend API | REST API + data store for match rooms and scores | Undesigned |
| Universal Links | Requires registered domain from D10 + `apple-app-site-association` file | Blocked by D10 |

---

## Phased Delivery

**Phase 1 — Core (after D08 auth is done):**
- Create/join match room in-app
- Short code + share sheet
- Score sync via polling (PATCH on each score entry, GET every 5s)
- Web scoreboard (static page, polling)
- Stroke play + match play supported

**Phase 2 — Real-time:**
- WebSocket push replaces polling
- Push notifications: "Mike just made birdie on 14!"
- Scorecard photo scanning pre-populates course setup in room

**Phase 3 — Social/Formats:**
- Best Ball, Wolf, 5-3-1 on live scoreboard
- Match history with spectator replay
- Buddy feed integration (D09)

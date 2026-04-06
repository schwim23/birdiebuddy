# Feature 013 — Collaborative Rounds

**Status:** Future (requires D08 — Auth; extends Feature 008 — Live Scoreboards)

---

## Overview

Multiple authenticated users join the same round session. Every participant sees all scores, the live scoreboard, and any recorded shot clips in real time — on their own device, in-app or on the web. Each player enters their own scores; no single device owns the round. Rounds are joinable via a unique short code or invite link.

This extends Feature 008 (Match Room / Live Scoreboards) with authenticated multi-device participation and video sync.

---

## Key Concepts

### Round Session
A single 18-hole round at one course on one day. Has:
- One or more **groups** (foursomes, threesomes, twosomes) playing simultaneously
- A **join code** (6-char) and invite link
- A **format** (stroke play, match play, Best Ball, Wolf, 5-3-1 — from 009)
- Optional parent **Event** (Feature 014)

### Group
A set of 2–4 players within a round session playing together. Scores are entered per player within a group. All groups' scores are visible to everyone in the round session.

### Participant Roles

| Role | Can enter scores | Can record video | Can see all groups | Can manage round |
|---|---|---|---|---|
| Creator | Own scores | Yes | Yes | Yes |
| Player | Own scores | Yes | Yes | No |
| Spectator | No | No | Yes | No |

---

## User Flows

### Creating a Round Session

1. Home screen → "Start Live Round"
2. Set: course, format, tee time, number of groups
3. Assign players to groups (by name + handicap, or invite by code later)
4. Tap "Create" → round session created on backend → join code + link generated
5. Share code/link via iOS share sheet

### Joining a Round Session

**In-app:**
1. Home screen → "Join Round" → enter 6-char code
2. App fetches round details → shows format, course, group assignments
3. User selects their player slot (or is pre-assigned)
4. Taps "Join" → linked to session; round starts when creator starts it

**Via link:**
- `birdiebuddy.app/join/X4K9PQ` → deep link → same join flow in-app
- If app not installed: web page shows round details + App Store link

### Entering Scores (in-round)

- Each player's device shows their own group's scoring UI (same as current `RoundView`)
- Scores sync to backend on entry; all other participants' devices update in real time
- Players can also see other groups' current hole and running scores via a "All Groups" tab
- Voice entry (004, 010) works as today — scores push to the shared session

### Shot Video Sync (012 integration)

- When a player saves a clip, it uploads to the backend (thumbnail immediately; full video on Wi-Fi or when round ends)
- All participants see new clip thumbnails appear in the round's clip feed
- Tapping a thumbnail streams the video (full download optional)
- Clips tagged with uploader's name, group, hole, shot type

---

## Data Model

```swift
// Server-side concepts mirrored locally

struct RoundSession: Codable, Identifiable {
    let id: UUID
    let code: String                  // 6-char join code
    let eventID: UUID?                // nil if standalone round
    let creatorUserID: String         // Sign in with Apple user ID
    let courseName: String
    let courseID: UUID?
    let format: GameFormat
    let scheduledTeeTime: Date?
    var groups: [RoundGroup]
    var status: RoundStatus
    var createdAt: Date
}

enum RoundStatus: String, Codable {
    case lobby       // created, players joining
    case active      // first score entered
    case completed   // all groups finished
}

struct RoundGroup: Codable, Identifiable {
    let id: UUID
    let roundSessionID: UUID
    var players: [SessionPlayer]
    var scores: [String: [Int: Int]]  // playerName → hole → strokes
    var currentHole: Int
}

struct SessionPlayer: Codable, Identifiable {
    let id: UUID
    let name: String
    let handicap: Int
    let userID: String?               // nil = guest player (named but no account)
    var role: ParticipantRole
}

enum ParticipantRole: String, Codable {
    case creator
    case player
    case spectator
}
```

**Local SwiftData additions:**
- `joinedSessions: [RoundSessionRef]` — lightweight list of sessions the user has joined, for home screen "recent live rounds"

---

## Backend API

Extends 008's API:

| Endpoint | Description |
|---|---|
| `POST /sessions` | Create a round session |
| `GET /sessions/{code}` | Fetch session state (all groups, all scores) |
| `POST /sessions/{code}/join` | Join as a player or spectator |
| `PATCH /sessions/{code}/groups/{groupID}/scores` | Push score update |
| `GET /sessions/{code}/clips` | List clip metadata (thumbnails) |
| `POST /sessions/{code}/clips` | Upload clip metadata + thumbnail |
| `GET /sessions/{code}/clips/{clipID}` | Stream full video |
| `WS /sessions/{code}/live` | WebSocket for real-time score + clip push (Phase 2) |

Phase 1 uses polling (GET every 5s). Phase 2 replaces with WebSocket push.

---

## UI Changes

### HomeView
- "Start Live Round" button (authenticated users)
- "Join Round" button — prompts for code
- Recent live rounds section (last 5 sessions)

### New screens

| Screen | Route | Description |
|---|---|---|
| `RoundLobbyView` | `.roundLobby` | Create session: course, format, groups, tee time |
| `JoinRoundView` | `.joinRound` | Enter code or scan QR, select player slot |
| `LiveRoundView` | `.liveRound(code:)` | Tabbed: My Group (scoring) + All Groups (spectate) + Clips |
| `AllGroupsView` | (tab within LiveRoundView) | Read-only scoreboard for all groups, live updating |
| `ClipFeedView` | (tab within LiveRoundView) | Chronological clip thumbnails from all players |

### RoundView integration
- When `AppState.currentSessionCode != nil`, score entries push to backend after local save
- "All Groups" floating button opens `AllGroupsView` as a sheet during the round

---

## Web Scoreboard (`birdiebuddy.app/live/{CODE}`)

Extends the 008 web scoreboard:
- Shows all groups, all players, all scores
- Groups displayed as collapsible sections
- Clip thumbnails listed per hole (click to play in browser)
- "Open in App" banner for iOS users

---

## Offline Behaviour

- Scores recorded locally if network drops; queued and synced when connectivity returns
- Videos recorded locally always; uploaded when back online
- Round can proceed fully offline; sync is best-effort

---

## Accessibility Identifiers

- `home.startLiveRoundButton`
- `home.joinRoundButton`
- `lobby.groupAssignment`
- `liveRound.myGroupTab`
- `liveRound.allGroupsTab`
- `liveRound.clipsTab`
- `liveRound.joinCode` — displays the session code for sharing

---

## Prerequisites

| Prereq | Feature |
|---|---|
| D08 — Auth | User identity for session ownership and joining |
| D10 — Hosting & Permissions | Backend API, video storage, WebSocket infrastructure |
| 008 — Live Scoreboards | Base match room concept and web scoreboard |
| 012 — Shot Video | Video recording and local storage |

---

## Phased Delivery

**Phase 1:**
- Create/join session, group assignment, invite code + link
- Score sync via polling (5s)
- All Groups read-only scoreboard (in-app + web)
- Clip thumbnail sync; full video on-demand

**Phase 2:**
- WebSocket real-time push
- Push notifications ("Eagle on 7!")
- QR code for join link
- Guest players (named but no account required)

**Phase 3:**
- In-round chat/reactions per hole
- Highlight reel auto-generated from session clips
- Integration with Feature 014 (Events)

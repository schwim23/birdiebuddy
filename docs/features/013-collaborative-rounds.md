# Feature 013 — Collaborative Rounds

**Status:** Future (requires D08 — Auth; D10 — CloudKit setup)

---

## Overview

Multiple users join the same round session. Every participant sees all scores and the live scoreboard in real time — on their own device. Each player enters their own scores; no single device owns the round. Rounds are joinable via a unique short code.

Built on **CloudKit** (iCloud). No custom backend required.

> **Future migration note:** CloudKit has no viable public web API. If a web scoreboard (`birdiebuddy.app/live/{CODE}`) becomes a hard requirement, this feature will need to be rewritten against a Supabase (or similar) backend. The data model below is designed to map cleanly to Postgres to minimise that rewrite cost.

---

## Key Concepts

### Round Session
A single 18-hole round at one course on one day. Has:
- One or more **groups** (foursomes, threesomes, twosomes) playing simultaneously
- A **join code** (6-char, derived from the CloudKit record ID)
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

## CloudKit Architecture

Uses the **public database** so participants can join without sharing an iCloud container explicitly. Record types live in the app's default CloudKit container (`iCloud.com.yourteam.birdiebuddy`).

### Record Types

```
RoundSession
  - code: String              // 6-char join code (first 6 chars of record ID)
  - creatorUserID: String     // CKRecord.creatorUserRecordID reference
  - courseName: String
  - courseID: String?
  - format: String            // GameFormat raw value
  - scheduledTeeTime: Date?
  - status: String            // "lobby" | "active" | "completed"
  - createdAt: Date

RoundGroup
  - roundSessionRef: CKRecord.Reference  // → RoundSession
  - groupIndex: Int

SessionPlayer
  - roundGroupRef: CKRecord.Reference    // → RoundGroup
  - name: String
  - handicap: Int
  - userRecordID: String?    // nil = guest player
  - role: String             // "creator" | "player" | "spectator"

ScoreEntry
  - roundGroupRef: CKRecord.Reference
  - playerName: String
  - hole: Int
  - strokes: Int
  - recordedAt: Date
```

### Realtime Sync

Use `CKQuerySubscription` on `ScoreEntry` and `SessionPlayer` record types filtered by `roundSessionRef`. CloudKit pushes a silent push notification on change; the app re-fetches affected records.

- APNs silent push → app wakes → fetch changed records → update local state → UI refreshes
- No polling. Works in background (iOS delivers silent pushes to suspended apps).
- Requires `Push Notifications` and `Background Modes > Remote notifications` capabilities.

---

## Auth Changes (vs. D08)

D08 as written uses Sign in with Apple with a custom Keychain store. With CloudKit:

- **No custom auth needed for CloudKit access** — CloudKit authenticates via the user's iCloud account automatically
- Sign in with Apple (D08) is still used for **identity** (display name, stable user ID for `SessionPlayer.userRecordID`)
- `AuthService` is simplified: Sign in with Apple → store name + userID in Keychain → pass userID to CloudKit records. No token verification needed on a backend.

---

## User Flows

### Creating a Round Session

1. Home screen → "Start Live Round" (requires iCloud account)
2. Set: course, format, tee time, number of groups
3. Assign players to groups (by name + handicap, or invite by code later)
4. Tap "Create" → `RoundSession` record saved to CloudKit public DB → join code generated
5. Share code via iOS share sheet

### Joining a Round Session

1. Home screen → "Join Round" → enter 6-char code
2. App queries CloudKit for `RoundSession` with matching code → shows format, course, groups
3. User selects their player slot (or is pre-assigned)
4. Taps "Join" → `SessionPlayer` record created in CloudKit → subscriptions activated

### Entering Scores (in-round)

- Each player's device shows their own group's scoring UI (same as current `RoundView`)
- On score entry: `ScoreEntry` record saved to CloudKit → subscription fires on all other devices → UI updates
- Players can see other groups' current hole and running scores via an "All Groups" tab
- Voice entry (004, 010) works as today — scores push to CloudKit after local save

### Shot Video Sync (012 integration)

- Clip metadata (thumbnail, tags) saved as a `ShotClip` CloudKit record attached to the session
- Full video stored in CloudKit Assets (attached to the `ShotClip` record)
- All participants see new clip thumbnails appear via subscription
- Tapping a thumbnail downloads the full video asset on demand

---

## Data Model (local mirror)

```swift
struct RoundSession: Codable, Identifiable {
    let id: UUID
    let code: String
    let eventID: UUID?
    let creatorUserID: String
    let courseName: String
    let courseID: UUID?
    let format: GameFormat
    let scheduledTeeTime: Date?
    var groups: [RoundGroup]
    var status: RoundStatus
    var createdAt: Date
}

enum RoundStatus: String, Codable {
    case lobby
    case active
    case completed
}

struct RoundGroup: Codable, Identifiable {
    let id: UUID
    let roundSessionID: UUID
    var players: [SessionPlayer]
    var scores: [String: [Int: Int]]   // playerName → hole → strokes
    var currentHole: Int
}

struct SessionPlayer: Codable, Identifiable {
    let id: UUID
    let name: String
    let handicap: Int
    let userID: String?
    var role: ParticipantRole
}

enum ParticipantRole: String, Codable {
    case creator
    case player
    case spectator
}
```

This struct layout maps directly to Postgres columns to minimise a future Supabase migration.

---

## CloudKit Service

New `CloudKitService.swift`:

```swift
final class CloudKitService {
    static let shared = CloudKitService()
    private let container = CKContainer.default()
    private let publicDB: CKDatabase

    func createSession(_ session: RoundSession) async throws -> String  // returns join code
    func fetchSession(code: String) async throws -> RoundSession
    func joinSession(code: String, player: SessionPlayer) async throws
    func saveScore(_ entry: ScoreEntry, sessionCode: String) async throws
    func subscribeToSession(code: String) async throws                  // sets up CKQuerySubscription
    func unsubscribeFromSession(code: String) async throws
}
```

---

## UI Changes

### HomeView
- "Start Live Round" button (requires iCloud sign-in — show prompt if iCloud unavailable)
- "Join Round" button — prompts for code
- Recent live rounds section (last 5 sessions, from local SwiftData `RoundSessionRef`)

### New screens

| Screen | Route | Description |
|---|---|---|
| `RoundLobbyView` | `.roundLobby` | Create session: course, format, groups, tee time |
| `JoinRoundView` | `.joinRound` | Enter code, select player slot |
| `LiveRoundView` | `.liveRound(code:)` | Tabbed: My Group (scoring) + All Groups (spectate) + Clips |
| `AllGroupsView` | (tab within LiveRoundView) | Read-only scoreboard for all groups, live updating |
| `ClipFeedView` | (tab within LiveRoundView) | Chronological clip thumbnails from all players |

---

## Offline Behaviour

- Scores recorded locally in `AppState` if CloudKit is unreachable
- Queued saves retried via `CKModifyRecordsOperation` with automatic retry on connectivity restore
- Round can proceed fully offline; sync is best-effort
- CloudKit handles conflict resolution (last-write-wins per `ScoreEntry` record)

---

## Accessibility Identifiers

- `home.startLiveRoundButton`
- `home.joinRoundButton`
- `lobby.groupAssignment`
- `liveRound.myGroupTab`
- `liveRound.allGroupsTab`
- `liveRound.clipsTab`
- `liveRound.joinCode`

---

## Prerequisites

| Prereq | Feature |
|---|---|
| D08 — Auth | User identity (display name, stable user ID) |
| D10 — CloudKit Setup | Container config, record types, subscriptions, capabilities |
| 012 — Shot Video | Video recording and local storage (for clip sync) |

---

## Phased Delivery

**Phase 1:**
- Create/join session, group assignment, invite code
- Score sync via CloudKit subscriptions
- All Groups read-only scoreboard (in-app)

**Phase 2:**
- Push notifications ("Eagle on 7!")
- QR code for join code
- Guest players (named but no iCloud account)
- Clip thumbnail sync via CloudKit Assets

**Phase 3:**
- In-round reactions per hole
- Integration with Feature 014 (Events)
- *(If web scoreboard required: migrate to Supabase backend)*

---

## Future Migration Path (CloudKit → Supabase)

If a web scoreboard becomes a hard requirement:

1. Spin up Supabase project; create tables matching the struct layout above (1:1 column mapping)
2. Replace `CloudKitService` with `SupabaseService` (same interface)
3. Migrate D08 auth: pass Apple identity token to Supabase Auth instead of Keychain only
4. Replace `CKQuerySubscription` with Supabase Realtime channel subscriptions
5. Add Next.js web scoreboard reading from Supabase

The local struct types (`RoundSession`, `RoundGroup`, etc.) do not change — only the persistence/sync layer swaps out.

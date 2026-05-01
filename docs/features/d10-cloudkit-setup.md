# Feature D10 — CloudKit Setup

**Status:** Future (required by Feature 013 — Collaborative Rounds)

---

## Overview

Configure the app's CloudKit container, define record types, enable push notification subscriptions, and add the required Xcode capabilities. No custom server or deployment needed — CloudKit is hosted by Apple.

> **Future migration note:** If a web scoreboard becomes a hard requirement, this feature's persistence layer will be replaced by Supabase. See the migration path in Feature 013.

---

## CloudKit Container

Container ID: `iCloud.com.yourteam.birdiebuddy`

Use the **public database** for all collaborative round data so participants can read/write without explicit sharing permissions. Personal round history (SwiftData) stays on-device only.

---

## Xcode Capabilities Required

In the BirdieBuddy target → Signing & Capabilities:

| Capability | Purpose |
|---|---|
| **iCloud** (CloudKit checkbox) | Enables CloudKit container access |
| **Push Notifications** | Delivers CloudKit subscription change notifications |
| **Background Modes → Remote notifications** | Wakes app on silent push to fetch updated records |

---

## Record Types

Define these in CloudKit Dashboard (or via schema migration in code on first launch):

### `RoundSession`
| Field | Type |
|---|---|
| `code` | String |
| `creatorUserRecordID` | String |
| `courseName` | String |
| `courseID` | String (optional) |
| `format` | String |
| `scheduledTeeTime` | Date/Time (optional) |
| `status` | String |
| `createdAt` | Date/Time |

### `RoundGroup`
| Field | Type |
|---|---|
| `roundSessionRef` | Reference → RoundSession |
| `groupIndex` | Int(64) |

### `SessionPlayer`
| Field | Type |
|---|---|
| `roundGroupRef` | Reference → RoundGroup |
| `name` | String |
| `handicap` | Int(64) |
| `userRecordID` | String (optional) |
| `role` | String |

### `ScoreEntry`
| Field | Type |
|---|---|
| `roundGroupRef` | Reference → RoundGroup |
| `playerName` | String |
| `hole` | Int(64) |
| `strokes` | Int(64) |
| `recordedAt` | Date/Time |

### `ShotClip` (added when Feature 012 Phase 3 is built)
| Field | Type |
|---|---|
| `roundSessionRef` | Reference → RoundSession |
| `playerName` | String |
| `hole` | Int(64) |
| `shotType` | String |
| `thumbnailAsset` | Asset |
| `videoAsset` | Asset (optional — uploaded later) |
| `recordedAt` | Date/Time |

---

## Indexes Required

CloudKit requires explicit indexes for queryable fields:

| Record Type | Field | Index Type |
|---|---|---|
| `RoundSession` | `code` | Queryable |
| `RoundSession` | `status` | Queryable |
| `RoundGroup` | `roundSessionRef` | Queryable |
| `SessionPlayer` | `roundGroupRef` | Queryable |
| `ScoreEntry` | `roundGroupRef` | Queryable |
| `ScoreEntry` | `recordedAt` | Sortable |
| `ShotClip` | `roundSessionRef` | Queryable |

---

## Subscriptions

Each device joining a session registers a `CKQuerySubscription` for `ScoreEntry` records matching the session's groups. CloudKit delivers a silent APNs push on any insert/update.

```swift
let predicate = NSPredicate(format: "roundGroupRef IN %@", groupRecordIDs)
let subscription = CKQuerySubscription(
    recordType: "ScoreEntry",
    predicate: predicate,
    subscriptionID: "scores-\(sessionCode)",
    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
)
let notificationInfo = CKSubscription.NotificationInfo()
notificationInfo.shouldSendContentAvailable = true  // silent push
subscription.notificationInfo = notificationInfo
```

Same pattern for `SessionPlayer` (to detect when new players join).

---

## `CloudKitService` — Key Operations

```swift
// Fetch session by join code
func fetchSession(code: String) async throws -> CKRecord

// Save a score entry
func saveScore(hole: Int, strokes: Int, playerName: String, groupRef: CKRecord.Reference) async throws

// Handle incoming silent push (called from AppDelegate/background task)
func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async
```

Error handling:
- `CKError.networkUnavailable` / `.networkFailure` → queue locally, retry with `CKModifyRecordsOperation`
- `CKError.serverRecordChanged` → last-write-wins (scores are append-only per hole; conflicts are rare)
- `CKError.notAuthenticated` → prompt user to sign in to iCloud in Settings

---

## iCloud Account Requirement

CloudKit public database reads work without an iCloud account. **Writes require iCloud sign-in.**

On `CKError.notAuthenticated`:
```swift
// Show non-blocking banner
"Sign in to iCloud in Settings to join live rounds."
```

Solo rounds (no CloudKit) are always available regardless of iCloud status.

---

## Testing

- Use the **CloudKit Dashboard** (developer.apple.com) to inspect records during development
- Use a second simulator or device signed in to a different iCloud account to test multi-device sync
- CloudKit is not available in unit tests — mock `CloudKitService` behind a protocol for testability:

```swift
protocol CloudKitServiceProtocol {
    func fetchSession(code: String) async throws -> RoundSession
    func saveScore(...) async throws
}
```

---

## Prerequisites

| Prereq | Reason |
|---|---|
| D08 — Auth | User identity for `SessionPlayer.userRecordID` |
| Apple Developer account | Required to create CloudKit container |

---

## Deliverables

- [ ] CloudKit container created in Apple Developer portal
- [ ] Record types and indexes defined in CloudKit Dashboard
- [ ] Xcode capabilities added (iCloud, Push Notifications, Background Modes)
- [ ] `CloudKitService.swift` with protocol + live implementation
- [ ] APNs entitlements in `BirdieBuddy.entitlements`
- [ ] Mock `CloudKitService` for unit tests

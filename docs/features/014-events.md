# Feature 014 — Multi-Round Events (Tournaments & Golf Trips)

**Status:** Future (requires 013 — Collaborative Rounds)

---

## Overview

An **Event** groups multiple round sessions under a single umbrella — a golf trip, a club tournament, a regular skins series, a Ryder Cup-style team competition. Everyone invited to the event can see all rounds, all groups, all scores, and all clips across the entire event. A single event join code gives access to everything inside it.

---

## Event Types

| Type | Description | Scoring |
|---|---|---|
| **Golf Trip** | 2–7 days, casual, multiple rounds per day possible | Per-round leaderboard + cumulative |
| **Stroke Play Tournament** | 1–4 rounds, lowest total wins | Cumulative gross / net over all rounds |
| **Match Play Bracket** | Single or double elimination | Head-to-head results, bracket progression |
| **Skins Series** | Per-hole skins, carry-overs, across multiple rounds | Total skins won |
| **Ryder Cup / Team Event** | Two teams, sessions worth points | Team points total |
| **Regular Series** | Recurring (monthly skins game, weekly Nassau) | Season-long points or stroke average |

---

## Key Concepts

### Event
Container for 1+ round sessions. Has:
- A **name** (e.g. "Myrtle Beach Trip 2027", "Club Championship")
- An **event join code** (6-char) — joining gives access to all rounds in the event
- An **event type** (see table above)
- An **admin** (creator) and optional co-admins
- A **participant list** with roles
- A **schedule** of round sessions (dates, courses, tee times)
- An **overall leaderboard** computed from all completed rounds

### Round Session within an Event
Same as Feature 013, but:
- Has a parent `eventID`
- Round join codes still work for direct access; event code grants access to all rounds
- Scores feed into the event-level leaderboard automatically

### Participant Roles

| Role | Permissions |
|---|---|
| Admin | Create/edit event, add rounds, manage participants, assign teams |
| Co-admin | Add rounds, manage participants |
| Player | Enter scores in their assigned group, see everything |
| Spectator | Read-only access to all rounds and clips |

---

## User Flows

### Creating an Event

1. Home → "Create Event"
2. Set: name, type, dates, description
3. Optionally add round sessions immediately (or add later)
4. Event created → event join code + link generated
5. Share via iOS share sheet

### Joining an Event

**In-app:**
1. Home → "Join Event" → enter event code
2. App shows event details: name, type, upcoming rounds, participant list
3. Tap "Join" → added as Player (or Spectator if configured)
4. All current and future rounds in the event are now accessible

**Via link:**
- `birdiebuddy.app/event/MYRTLE27` → deep link → same join flow

### Adding a Round to an Event

Admin flow (from Event detail screen):
1. Tap "Add Round"
2. Set: date, course, format, group count, tee time
3. Round session created, linked to event
4. Participants auto-notified (push notification)

### Group Assignment

- Admin assigns players to groups per round
- Or: admin sets group size limit and lets players self-assign (first-come, up to limit)
- Unassigned participants default to Spectator for that round

---

## Data Model

```swift
struct Event: Codable, Identifiable {
    let id: UUID
    let code: String                    // 6-char event join code
    let name: String
    let type: EventType
    var adminUserIDs: [String]
    var participantIDs: [String]        // Sign in with Apple user IDs
    var roundSessionIDs: [UUID]
    var teamAssignments: [[String]]?    // for team events: array of teams, each an array of userIDs
    var startDate: Date
    var endDate: Date?
    var status: EventStatus
    var createdAt: Date
}

enum EventType: String, CaseIterable, Codable {
    case golfTrip        = "Golf Trip"
    case strokePlay      = "Stroke Play Tournament"
    case matchPlayBracket = "Match Play Bracket"
    case skinsSeries     = "Skins Series"
    case teamEvent       = "Team Event"
    case regularSeries   = "Regular Series"
}

enum EventStatus: String, Codable {
    case upcoming    // no rounds started
    case active      // at least one round in progress or completed
    case completed   // all rounds completed
}
```

---

## Event Leaderboard

Computed server-side from all completed rounds within the event. Logic varies by type:

**Stroke Play Tournament:**
- Sum gross and net scores per player across all rounds
- Leaderboard sorted by net total; ties broken by gross

**Match Play Bracket:**
- Win/loss/halve record per player
- Bracket diagram showing progression
- Final result: champion

**Skins Series:**
- Total skins won per player across all rounds (carry-over skins roll to next hole)
- Per-round skins breakdown

**Team Event:**
- Points per match (e.g. 1 pt win, 0.5 pt halve, 0 pt loss)
- Team totals; individual contribution breakdown

**Golf Trip / Regular Series:**
- Per-round leaderboard
- Running totals and averages
- "Best round" and "worst round" highlights

---

## UI Changes

### HomeView
- "My Events" section — upcoming and active events
- "Create Event" and "Join Event" buttons

### New Screens

| Screen | Route | Description |
|---|---|---|
| `EventListView` | `.events` | All events the user is part of |
| `EventDetailView` | `.event(id:)` | Event overview: rounds, leaderboard, participants, clips |
| `CreateEventView` | `.createEvent` | Name, type, dates, settings |
| `JoinEventView` | `.joinEvent` | Enter event code |
| `EventLeaderboardView` | (tab in EventDetailView) | Overall standings across all rounds |
| `EventScheduleView` | (tab in EventDetailView) | Round list with dates, courses, status |
| `EventClipFeedView` | (tab in EventDetailView) | All clips from all rounds in the event |
| `BracketView` | (tab in EventDetailView, match play only) | Match play bracket diagram |

### Web (`birdiebuddy.app/event/{CODE}`)

- Public event page (if event is set to public visibility)
- Tabs: Leaderboard, Schedule, Clips
- Each round links to its own live scoreboard (008/013)
- No auth required to view (public events); private events require invite token

---

## Notifications

Push notifications sent to all event participants:

| Trigger | Message |
|---|---|
| New round added | "Admin added Saturday's round at Pine Valley — tap to see details" |
| Round starting | "Tee time in 30 minutes — Round 2 at Bethpage Black" |
| Eagle / ace | "Mike just made an eagle on hole 7!" |
| Round completed | "Round 2 complete — Mike leads at -4 through 36 holes" |
| Event result | "Final results: Mike wins the trip at -8 total" |

---

## Backend API

Extends 013's API:

| Endpoint | Description |
|---|---|
| `POST /events` | Create event |
| `GET /events/{code}` | Fetch event details + leaderboard |
| `POST /events/{code}/join` | Join event |
| `POST /events/{code}/rounds` | Add a round session to event |
| `GET /events/{code}/leaderboard` | Computed overall standings |
| `GET /events/{code}/clips` | All clips across all rounds |
| `WS /events/{code}/live` | WebSocket for event-level notifications |

---

## Accessibility Identifiers

- `home.createEventButton`
- `home.joinEventButton`
- `event.leaderboardTab`
- `event.scheduleTab`
- `event.clipsTab`
- `event.joinCode`
- `event.participantList`

---

## Prerequisites

| Prereq | Feature |
|---|---|
| D08 — Auth | User identity and admin permissions |
| D10 — Hosting & Permissions | Backend, push notifications, video storage |
| 013 — Collaborative Rounds | Round sessions, group scoring, clip sync |

---

## Phased Delivery

**Phase 1 — Golf Trip + Stroke Play:**
- Create/join event with code
- Add rounds to event; event leaderboard for stroke play and golf trip types
- All rounds + clips visible to all participants
- Web event page (public events)

**Phase 2 — Formats + Notifications:**
- Match play bracket, skins series, team event scoring
- Push notifications (new round, eagle alerts, results)
- Group self-assignment

**Phase 3 — Social + Series:**
- Regular series (recurring monthly/weekly)
- Season-long stats and history
- Event highlight reel from all clips
- Public event discovery (find a tournament to spectate)

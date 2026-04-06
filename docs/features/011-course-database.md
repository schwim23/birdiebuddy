# Feature 011 — Course Database with Real Hole Data

**Status:** Future (no blockers for local bundled data; live API requires D08 + D10)

---

## Overview

Replace the current default 18-hole par-4 placeholder with a searchable database of real golf courses, each with accurate hole pars, yardages, stroke indexes, slope rating, and course rating. The initial version ships a bundled local dataset; a later phase connects to a live course API.

---

## Data per Course

| Field | Description |
|---|---|
| `name` | Full course name (e.g. "Pebble Beach Golf Links") |
| `location` | City, State / Country |
| `holes[1…18].par` | Par for each hole (3, 4, or 5) |
| `holes[1…18].yardage` | Yardage from each tee set |
| `holes[1…18].strokeIndex` | Difficulty ranking 1–18 (for handicap allocation) |
| `slopeRating` | 55–155; used for handicap index conversion |
| `courseRating` | Decimal (e.g. 74.2); used with slope for net differential |
| `tees` | Named tee sets (Black, Blue, White, Red, Gold) |

---

## Data Model

```swift
struct CourseHole: Codable {
    let number: Int           // 1–18
    let par: Int              // 3, 4, or 5
    let strokeIndex: Int      // 1–18
    let yardages: [String: Int]  // tee name → yards (e.g. ["Blue": 412])
}

struct CourseRecord: Codable, Identifiable {
    let id: UUID
    let name: String
    let city: String
    let state: String         // ISO 3166-2 subdivision code
    let country: String       // ISO 3166-1 alpha-2
    let holes: [CourseHole]   // always 18 elements
    let tees: [String]        // ordered tee names, longest → shortest
    let slopeRating: [String: Int]     // tee name → slope
    let courseRating: [String: Double] // tee name → rating
    let source: CourseDataSource
}

enum CourseDataSource: String, Codable {
    case bundled   // shipped with app, static JSON
    case userCreated  // entered manually via CourseSetupView
    case api       // fetched from live course API (Phase 2)
}
```

**`CourseSetup` SwiftData model** (already exists) gains:
- `courseRecordID: UUID?` — links to a `CourseRecord` from the database
- `teeSelection: String?` — which tee set was played

---

## Local Bundled Dataset (Phase 1)

Ship a `courses.json` file in the app bundle covering:
- ~500 well-known US public courses
- All 50 US states represented
- Fields: name, city, state, hole pars, stroke indexes, slope/course rating for one tee set (Blue/White)
- Source: open data (e.g. USGA public course data, OpenStreetMap golf relations, or manually curated)

The dataset is read once at launch and cached in memory. No network required.

```swift
// CourseDatabase.swift
enum CourseDatabase {
    static let shared: [CourseRecord] = {
        guard let url = Bundle.main.url(forResource: "courses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let courses = try? JSONDecoder().decode([CourseRecord].self, from: data)
        else { return [] }
        return courses
    }()

    static func search(_ query: String) -> [CourseRecord] {
        guard !query.isEmpty else { return shared }
        let q = query.lowercased()
        return shared.filter {
            $0.name.lowercased().contains(q) || $0.city.lowercased().contains(q)
        }
    }
}
```

---

## UI Changes

### SetupView — Course Picker

Replace the current "Custom Course / Default" toggle with a searchable course picker:

1. Search field — user types course name or city
2. Results list — name, city, state
3. Tee selection — picker appears after course is selected
4. "Enter manually" fallback — opens existing `CourseSetupView` for custom entry

**Flow:**
```
SetupView
  └─ "Select Course" row
       └─ CoursePickerView (search + list)
            └─ TeePickerView (after course selected)
                 → fills roundPar + roundStrokeIndex in AppState
```

### CoursePickerView (new screen)

- `AppRoute.coursePicker` — new route
- Search field with debounce (150ms)
- Sorted results: exact name match first, then city match
- "Use my location" option (CoreLocation) to sort nearby courses first (Phase 2)
- "Add course manually" footer row → existing `CourseSetupView`

---

## Handicap Index → Playing Handicap Conversion (Phase 2)

Once slope/course rating is available, calculate the player's **playing handicap** for the round rather than using the raw handicap number:

```
Playing Handicap = round(Handicap Index × (Slope / 113) + (Course Rating − Par))
```

This replaces the current direct use of `player.handicap` in stroke allocation and is the USGA-compliant method.

Phase 1 continues using raw handicap as today. Phase 2 applies the formula when `CourseRecord.slopeRating` and `courseRating` are available.

---

## Live Course API (Phase 2 — requires D08 + D10)

- `GET /courses?q={query}` — search by name/location
- `GET /courses/{id}` — full hole-level data
- Results cached locally (SwiftData or `URLCache`) for offline use during a round
- Falls back to bundled data if network unavailable

Candidate APIs: GHIN API (USGA), GolfAPI.io, or custom scraped dataset hosted under D10 infrastructure.

---

## Accessibility Identifiers

- `setup.coursePickerButton` — opens the course picker
- `setup.courseSearchField` — search text field
- `setup.courseResultRow` — individual search result row
- `setup.teePickerButton` — tee selection control

---

## Phased Delivery

**Phase 1 — Bundled data:**
- `courses.json` in app bundle (~500 US courses)
- `CourseDatabase` singleton
- `CoursePickerView` with search
- Tee selection → fills par + stroke index in `AppState`
- "Enter manually" fallback to `CourseSetupView`

**Phase 2 — Smart features:**
- CoreLocation for nearby course sorting
- Live course API with local caching
- Playing handicap calculation from slope/course rating

**Phase 3 — Community:**
- User-submitted course corrections
- User-created courses shared via D10 backend
- Scorecard photo scanning pre-populates a new course entry (D04b integration)

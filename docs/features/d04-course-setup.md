# Feature D04 — Course Setup Screen

## Goal
Let players configure a real course (name, slope/rating, par per hole, stroke index per hole)
so that handicap dots, scoring colors, and subtotals all use actual course data.

## Data model — CourseSetup (@Model)
```swift
@Model final class CourseSetup {
    var id: UUID
    var name: String
    var slopeRating: Int        // 55–155
    var courseRating: Double    // e.g. 72.1
    var parArray: [Int]         // 18 values, index 0 = hole 1; valid: 3,4,5
    var strokeIndexArray: [Int] // 18 values, each unique 1–18
}
```
Default values: all pars = 4, SI = Course.defaultStrokeIndex, slope = 113, rating = 72.0

## AppState additions
- `roundPar: [Int: Int]`        — set at startRound, defaults to Course.defaultPar
- `roundStrokeIndex: [Int: Int]`— set at startRound, defaults to Course.defaultStrokeIndex
- `func par(for hole: Int) -> Int` helper
- `func strokeIndex(for hole: Int) -> Int` helper
- `startRound(with:format:course:)` accepts optional CourseSetup

## Course picker in SetupView
- Section "Course" above the Format picker
- Picker shows "Default" + names of all saved CourseSetup objects
- Button "Set up new course →" navigates to CourseSetupView

## CourseSetupView
- NavigationTitle: "Course Setup" (edit) / "New Course"
- Text field: course name
- Stepper: slope rating (55–155), default 113
- Stepper: course rating ×10 displayed as decimal (e.g. 720 → "72.0"), range 600–800
- List of 18 holes, each row:
  - "Hole N" label
  - Par picker: 3 / 4 / 5 (segmented)
  - SI stepper: 1–18
- Save button inserts/updates via modelContext
- Delete button (edit mode only)

## Affected views
- RoundView: use `appState.par(for: displayHole)` instead of `let par = 4`
- ScorecardView: use `appState.par(for: hole)` instead of `Course.defaultPar[hole]`
- SummaryView ScoringProfile: already uses `Course.defaultPar` — update to `appState.roundPar`
  (ScoringProfile initializer receives `roundPar: [Int: Int]`)

## Accessibility Identifiers
- `courseSetup.nameField`
- `courseSetup.saveButton`
- `setup.coursePicker`
- `setup.newCourseButton`

## Notes
- A round always gets a snapshot of par/SI at start — editing a course mid-round has no effect
- "Default" course uses Course.defaultPar + Course.defaultStrokeIndex (all par 4s)
- CourseSetup added to modelContainer alongside PlayerProfile + RoundRecord

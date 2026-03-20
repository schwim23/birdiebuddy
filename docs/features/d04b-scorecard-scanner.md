# Feature D04b — Scorecard Photo Scanner

## Goal
Let players photograph a paper scorecard and automatically populate the course
setup form (name, slope, rating, par per hole, stroke index per hole) using
on-device OCR via the Vision framework.

## User flow
1. In CourseSetupView tap "Scan Scorecard" (camera icon button in the Course Info section)
2. iOS photo picker opens (camera + library)
3. User picks/takes photo
4. Vision OCR runs on-device; extracted fields are applied to the form
5. User reviews, corrects anything Vision missed, then saves normally

## Implementation

### ScorecardParser.swift
Static service using Vision `VNRecognizeTextRequest` (accurate mode):
- Groups recognized text observations into rows by Y-coordinate proximity
- Sorts each row left→right by X coordinate
- Extracts course name (first non-numeric, non-keyword prominent line)
- Finds slope (keyword "slope" + adjacent 55–155 integer)
- Finds rating (keyword "rating" + adjacent 65.0–80.0 decimal, or standalone decimal in range)
- Finds par row: 9 or 18 consecutive integers all in {3, 4, 5}
- Finds handicap/SI row: 9 or 18 consecutive unique integers in 1–18

### ScorecardScanResult struct
```swift
struct ScorecardScanResult {
    var courseName: String?
    var slopeRating: Int?
    var courseRatingTimes10: Int?   // e.g. 724 → "72.4"
    var parValues: [Int]?           // 18 values (front + back combined if found)
    var handicapValues: [Int]?      // 18 values
}
```

### CourseSetupView changes
- "Scan Scorecard" button above the Course Info fields
- Uses `PhotosPicker` (PhotosUI) to get a `UIImage`
- Calls `ScorecardParser.scan(image:)` → async → applies result to `@State` fields
- Shows a brief "Scanning…" progress indicator while Vision runs
- After scan, shows an alert summarizing what was found (e.g. "Found slope 128, rating 71.4, par for all 18 holes, handicaps for all 18 holes")

## Privacy
- Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to Info.plist

## Accessibility
- `courseSetup.scanButton` — the scan button

## Notes
- Scorecards split into front 9 / back 9 tables; parser handles either 9-value
  or 18-value rows and stitches front+back together
- No network calls — fully on-device Vision OCR
- Unrecognized fields stay at their current default values

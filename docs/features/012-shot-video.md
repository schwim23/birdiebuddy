# Feature 012 — Shot Video Recording

**Status:** Future (no blockers for local recording; sharing requires D08 + D10)

---

## Overview

Players can record a short video clip of any shot during a round. Each clip is automatically tagged with the player, course, hole number, and shot context (e.g. tee shot, approach, chip, putt). Videos are stored on-device and can be reviewed in the round summary or player history. Sharing is a later phase.

---

## User Stories

1. **Recording:** During a round, player taps a camera button on their row → app records a short clip (up to 30s) → clip is saved tagged to that player, hole, and course.
2. **Review in summary:** After the round, summary screen shows a "Clips" section listing all videos from the round, grouped by hole.
3. **Review in history:** From the home screen, a player's past rounds show any saved clips alongside their scores.
4. **Playback:** Tap a clip thumbnail to play it full-screen with the tag info (player, hole, shot type, score on that hole) shown as an overlay.

---

## Data Model

```swift
@Model
final class ShotClip {
    var id: UUID
    var date: Date
    var playerName: String
    var courseID: UUID?         // nil if no course was selected for the round
    var courseName: String?     // denormalised for display
    var hole: Int               // 1–18
    var shotType: ShotType
    var score: Int?             // strokes recorded on that hole (filled after hole completes)
    var localURL: URL           // path to .mov file in app's Documents directory
    var durationSeconds: Double
    var roundRecordID: UUID?    // links to RoundRecord if round was saved

    init(playerName: String, hole: Int, shotType: ShotType,
         courseID: UUID?, courseName: String?, roundRecordID: UUID?) {
        self.id = UUID()
        self.date = .now
        self.playerName = playerName
        self.hole = hole
        self.shotType = shotType
        self.courseID = courseID
        self.courseName = courseName
        self.roundRecordID = roundRecordID
        self.localURL = ShotClip.newClipURL()
        self.durationSeconds = 0
    }

    private static func newClipURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("clips/\(UUID().uuidString).mov")
    }
}

enum ShotType: String, CaseIterable, Codable {
    case teeShot   = "Tee Shot"
    case approach  = "Approach"
    case chip      = "Chip"
    case putt      = "Putt"
    case bunker    = "Bunker"
    case other     = "Other"
}
```

---

## Recording Flow

### In-round (RoundView)

- Each player row gains a small **camera icon** button alongside the score entry
- Tapping it opens `ShotRecorderView` (sheet or full-screen cover):
  1. Shot type picker (Tee Shot / Approach / Chip / Putt / Bunker / Other)
  2. Live camera preview using `AVCaptureSession`
  3. Record button — tap to start, tap again to stop (max 30s, auto-stops at limit)
  4. Brief playback preview of the clip
  5. "Save" or "Retake"
- On save: `ShotClip` written to SwiftData; video file written to `Documents/clips/`
- Recording is optional — score entry is unaffected

### New service: `ShotRecorder.swift`

```swift
final class ShotRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    func startSession() throws   // sets up AVCaptureSession
    func startRecording(to url: URL)
    func stopRecording()         // triggers delegate callback with final URL + duration
    func stopSession()
}
```

Uses `AVCaptureMovieFileOutput`. Requests `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` permissions.

---

## UI Changes

| Screen | Change |
|---|---|
| `RoundView` | Camera icon on each player row; tapping opens `ShotRecorderView` |
| `ShotRecorderView` | New full-screen sheet: shot type picker, camera preview, record/stop/save |
| `SummaryView` | "Clips" section below scores — thumbnails grouped by hole; tap to play |
| `HomeView` | Recent rounds show clip count badge ("3 clips") next to round entry |
| `ClipPlayerView` | New full-screen video player with tag overlay (player, hole, shot type, score) |

---

## Storage & Cleanup

- Clips stored in `Documents/clips/` — included in iCloud backup by default
- `ShotClip.localURL` is a relative path resolved at runtime (handles app reinstall / device migration)
- Orphan cleanup: on launch, scan `Documents/clips/` and delete any `.mov` files with no matching `ShotClip` SwiftData record
- User can delete individual clips from `ClipPlayerView` or the summary screen (swipe to delete)
- No automatic expiry — clips kept until user deletes them

---

## Accessibility Identifiers

- `round.recordShotButton` — camera icon on player row
- `shotRecorder.shotTypePicker` — shot type selector
- `shotRecorder.recordButton` — start/stop recording
- `shotRecorder.saveButton` — confirm and save clip
- `summary.clipsSection` — clips list in summary
- `summary.clipThumbnail` — individual clip thumbnail

---

## Permissions Required

| Permission | Key | Usage |
|---|---|---|
| Camera | `NSCameraUsageDescription` | Record shot video |
| Microphone | `NSMicrophoneUsageDescription` | Capture audio with clip |

---

## Phased Delivery

**Phase 1 — Local recording:**
- `ShotClip` SwiftData model
- `ShotRecorder` service (AVFoundation)
- `ShotRecorderView` in-round sheet
- Clips section in `SummaryView`
- `ClipPlayerView` with tag overlay
- Clip deletion and orphan cleanup

**Phase 2 — History integration:**
- Clip count badge on home screen round entries
- Filter past rounds by "has clips"
- Clip gallery per player across all rounds

**Phase 3 — Sharing (requires D08 + D10):**
- Share individual clip via iOS share sheet (AirDrop, Messages, etc.)
- Upload clip to D10 backend, attach to live match room (008 integration)
- "Highlight reel" — auto-edit best clips from a round into a short video (AVFoundation composition)

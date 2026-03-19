# BirdieBuddy — Complete App Specification & Design System

## 1. App Overview
**BirdieBuddy** is a premium golf companion mobile application designed for both casual players and competitive golfers. It combines GPS-based rangefinding, digital scorekeeping, and deep statistical analysis with a social layer for community engagement.

---

## 2. Core User Flows

1. **Onboarding:** Sign up, club bag setup (entering average distances), and favorite course selection.
2. **Starting a Round:** GPS-based course search → Select Tee Box → Start Round.
3. **In-Play GPS/Tracking:** View hole layout → Get distances → Log shot (Club + Result).
4. **Scorekeeping:** Enter strokes/putts after each hole → Review scorecard.
5. **Post-Round Analysis:** Review round summary → View updated handicap and stats.

---

## 3. Detailed Screen Specifications

### 3.1 Dashboard (Home)
- **Primary CTA:** "Start New Round" (Large, high-visibility button).
- **Recent Rounds:** Scrollable list of last 3 rounds with scores and dates.
- **Handicap Tracker:** Hero card displaying current calculated handicap and trend (Up/Down).
- **Course Weather:** Real-time wind speed/direction and temperature for the nearest course.

### 3.2 GPS Rangefinder (Live Round)
- **Map View:** Interactive satellite map with draggable pin for precise distance.
- **Yardage Cards:** Large font for Front/Center/Back of green.
- **Club Recommendation:** AI-suggested club based on distance and player's "Club Bag" data.
- **Quick-Log:** One-tap button to log "Fairway Hit" or "Green in Regulation".

### 3.3 Digital Scorecard
- **Entry Grid:** Tap-based interface for Strokes, Putts, Penalties, and Sand Saves.
- **Full View:** Landscape-optimized traditional 18-hole grid.
- **Live Leaderboard:** If playing in a "Buddy Group," show real-time rankings.

### 3.4 Stats & Analytics
- **Driving Accuracy:** Heatmap of missed fairways (Left/Right/Short).
- **Putting Stats:** Average putts per hole and "3-Putt Avoidance" percentage.
- **Scoring Profile:** Pie chart of Birdies, Pars, Bogeys, etc.

---

## 4. Feature Backlog (Current Sprint)
- [ ] **Auth:** Social login (Google/Apple) and email/password.
- [ ] **Course Database:** Integration with a global golf course API (e.g., Google Maps + Golf API).
- [ ] **Club Management:** CRUD operations for user's golf bag.
- [ ] **Offline Mode:** Basic scorekeeping capability without active GPS/Data.
- [ ] **Unit Toggle:** Support for both Yards and Meters.

---

## 5. Future Features Roadmap

### Phase 2: Social & Community
- **Buddy Feed:** A social timeline where users can like and comment on friends' rounds.
- **Group Tournaments:** Create private "Mini-Tours" with multi-day scoring.
- **Course Reviews:** User-submitted photos and "Conditions" updates (e.g., "Greens are fast today").

### Phase 3: Advanced AI & Hardware
- **Swing Analysis:** Use device camera and AI to analyze swing tempo and plane.
- **Smartwatch Integration:** Native Apple Watch and Wear OS apps for quick yardages on the wrist.
- **AR View:** Use the camera to see a virtual pin and distance overlays on the real terrain.
- **Weather Impact:** Adjust "Plays Like" distance based on wind and elevation.

---

## 6. Design System Guidelines

### 6.1 Typography
- **Primary:** Inter or Montserrat (sans-serif) for maximum legibility outdoors.
- **Hierarchy:**
  - H1: 34pt Bold — hole numbers, key scores
  - H2: 28pt Semibold — section headers
  - Body: 17pt Regular — player names, scores
  - Caption: 13pt Regular — secondary info (handicap, par)

### 6.2 Color Palette
| Token            | Hex       | Usage                         |
|------------------|-----------|-------------------------------|
| Emerald Green    | `#2E7D32` | Primary actions, backgrounds  |
| Fairway White    | `#F5F5F5` | Card/screen backgrounds       |
| Sand Trap Gold   | `#FFC107` | Highlights, awards, dots      |
| Deep Navy        | `#1A237E` | Secondary nav, data labels    |
| Birdie Blue      | `#1976D2` | Score indicators, links       |
| Rough Red        | `#C62828` | Errors, bogey/over-par        |
| Text Primary     | `#212121` | Main body text                |
| Text Secondary   | `#757575` | Labels, captions              |

### 6.3 Components
- **Touch Targets:** Minimum 48×48pt (outdoor use — gloves, sunlight).
- **Cards:** 12pt corner radius, 1pt `#E0E0E0` border, white background.
- **Primary Button:** Full-width, 56pt height, 12pt radius, Emerald Green fill, white text.
- **Score Entry Field:** 52×44pt, `systemGray6` background, centered bold number, number pad keyboard.
- **Status Bars:** High-contrast for direct sunlight visibility.
- **Handicap Stroke Dot:** `●` (filled circle), 10pt, `.primary` color, displayed inline with player name.

### 6.4 Spacing
- Base unit: 8pt
- Component padding: 16pt horizontal, 12pt vertical
- Section spacing: 24pt
- Screen edge margins: 16pt

### 6.5 Icons & Logo
See `docs/brand/logo.svg` for the master logo mark.
The app icon uses the same bird + flag composition on an Emerald Green background.
- **Bird:** White stylized bird silhouette (soaring profile, facing right)
- **Flag:** White pole with Sand Trap Gold triangular flag
- **Background:** Solid Emerald Green `#2E7D32`

---

## 7. Screen Implementation Priority

These screens are derived from the design spec and should be built in the following order after the current MVP scorekeeping foundation is solid:

### Tier 1 — Scorecard Polish (immediate)
1. **Home screen redesign** — Add recent rounds list + handicap hero card
2. **Scorecard full-screen landscape view** — Traditional 18-hole grid
3. **Round summary redesign** — Scoring profile chart (birdies/pars/bogeys breakdown)

### Tier 2 — Course & Data
4. **Course setup screen** — Enter par per hole, stroke index per hole, slope/rating
5. **Club bag setup** — CRUD list of clubs with average distances
6. **Stats dashboard** — Driving accuracy, putting stats, scoring distribution

### Tier 3 — GPS & Live Play
7. **GPS rangefinder** — CoreLocation-based yardage to green (no third-party map required for MVP)
8. **Shot log** — Per-shot club and result logging during a hole
9. **Course map view** — Satellite tile overlay with green/pin markers

### Tier 4 — Social
10. **Auth screen** — Sign in with Apple + email
11. **Buddy feed** — Round sharing timeline
12. **Group tournament** — Multi-day leaderboard

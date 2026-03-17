# Architecture Overview

## App Goal
A voice-friendly golf scoring app for casual rounds, expanding later to tournaments and match formats.

## Tech Stack
- SwiftUI (iOS 17+)
- Swift 5.9+
- Local-first data (in-memory for MVP, SwiftData migration planned)
- XCUITest for UI automation

## Initial Scope
- Single player
- 18-hole round
- Per-hole par and strokes
- Simple round summary

## Data Model

### Round
- id: UUID
- date: Date
- courseName: String
- currentHole: Int
- isFinished: Bool

### HoleScore
- id: UUID
- roundId: UUID
- holeNumber: Int
- par: Int
- strokes: Int

## Design Principles
- Structure model types so they can adopt @Model (SwiftData) without a rewrite
- Local-first MVP — no networking
- Deterministic test mode with stable accessibility identifiers
- PR-only development — never commit directly to main

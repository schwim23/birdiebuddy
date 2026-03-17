# Claude Code Instructions for Birdie Buddy

You are working on Birdie Buddy, an iOS golf scoring app built with SwiftUI targeting iOS 17+.

## Product Priority
Always optimize for:
1. A working iOS app in Simulator
2. Deterministic automated tests
3. Small incremental changes
4. Clean, readable SwiftUI code

## Tech Constraints
- SwiftUI only — no UIKit unless absolutely necessary
- iOS 17+ deployment target
- Swift 5.9+
- In-memory state for MVP (structure types for future SwiftData migration)
- No third-party dependencies in MVP

## Current Phase: MVP
- Start round
- Enter score per hole
- Advance through 18 holes
- Round summary
- UI automation support via XCUITest

## Rules
- Never redesign the whole app in one pass
- Do not add tournaments, multiplayer, or voice unless the feature spec explicitly asks
- Keep changes small and targeted — one feature per branch
- Add or preserve accessibility identifiers required by docs/features/003-test-mode.md
- Prefer simple in-memory state before adding persistence
- If a build fails, fix the smallest root cause first
- If tests fail, inspect the failure output and patch only what's necessary
- Use meaningful commit messages

## Working Agreement
Before making changes:
1. Read this file (CLAUDE.md)
2. Read docs/architecture/overview.md
3. Read the relevant file in docs/features/
4. Summarize your plan before writing code

## Error Handling Patterns
- Use Swift's Result type or throwing functions — not force unwraps
- Guard against invalid state (hole number out of range, nil scores)
- Provide sensible defaults rather than crashing

## Build & Test Commands
- Build: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -scheme BirdieBuddy -destination 'platform=iOS Simulator,name=iPhone 17'
- Test: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -scheme BirdieBuddy -destination 'platform=iOS Simulator,name=iPhone 17'
- Or use XcodeBuildMCP if available
- Note: iPhone 16 simulator unavailable; use iPhone 17 (iOS 26.2)

## Git Rules
- Never commit directly to main
- Work on a feature branch (feature/xxx or test/xxx)
- Make focused commits with clear messages
- Prepare changes suitable for a PR

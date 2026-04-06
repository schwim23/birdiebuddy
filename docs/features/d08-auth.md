# Feature D08 — Authentication (Sign in with Apple)

**Status:** Future (required by Feature 013 — Collaborative Rounds; Feature 014 — Events)

---

## Overview

Users can sign in with their Apple ID to unlock features that require a persistent identity: creating and joining live round sessions, saving clips to the cloud, and participating in events. Sign-in is optional — the app works fully without an account for solo and local multi-player rounds.

---

## User Stories

1. **Sign in:** From the home screen, user taps "Sign In" → Sign in with Apple sheet appears → user authenticates → app receives a user ID + display name → user is signed in.
2. **Stay signed in:** Auth token is persisted in Keychain. On next launch the user is automatically signed in without re-authenticating.
3. **Sign out:** From Settings, user taps "Sign Out" → token cleared → user returns to unauthenticated state. Local round history is preserved.
4. **Gated features:** "Start Live Round" and "Join Round" buttons on HomeView prompt sign-in if the user is not authenticated.
5. **Display name:** The name returned by Apple (first + last, or custom) is used as the default player name during round setup. User can still change it.

---

## Constraints

- Sign in with Apple is the only supported provider (App Store requirement for social login).
- Auth is additive — all existing local features (solo rounds, voice entry, scorecard scanner) remain fully functional without an account.
- No third-party SDKs. Use `AuthenticationServices` framework (built into iOS 17).
- Tokens stored in Keychain via `KeychainHelper` (new, internal utility — no third-party wrapper).

---

## Data Model

```swift
// In-memory, populated on launch from Keychain
struct AuthSession {
    let userID: String          // Sign in with Apple stable user ID
    let displayName: String     // Full name from Apple credential (stored on first sign-in)
    let email: String?          // May be nil or relay address; store on first sign-in only
    let credential: String      // Identity token (JWT) for backend verification
}

// AppState additions
var authSession: AuthSession? = nil
var isSignedIn: Bool { authSession != nil }
```

**Keychain entries** (stored under app bundle ID):
- `auth.userID` — stable Apple user ID
- `auth.displayName` — name captured on first sign-in (Apple only sends this once)
- `auth.email` — email captured on first sign-in
- `auth.identityToken` — JWT for backend verification

> Apple only provides the user's name and email on the **first** sign-in. These must be saved immediately on first authentication or they are lost.

---

## Implementation

### `SignInWithAppleButton` (SwiftUI)

Use `SignInWithAppleButton` from `AuthenticationServices` directly — no wrapper needed.

```swift
SignInWithAppleButton(.signIn) { request in
    request.requestedScopes = [.fullName, .email]
} onCompletion: { result in
    // handle ASAuthorization or Error
}
.signInWithAppleButtonStyle(.black)
.frame(height: 50)
.accessibilityIdentifier("auth.signInWithAppleButton")
```

### `AuthService`

New internal service. Responsibilities:
- Handle `ASAuthorizationAppleIDProvider` credential request
- Persist credentials to Keychain on first sign-in
- Restore session from Keychain on launch
- Validate credential state on launch (`getCredentialState(forUserID:)`) — revoke session if `.revoked` or `.notFound`
- Sign out (clear Keychain entries, nil out `AppState.authSession`)

```swift
final class AuthService {
    static let shared = AuthService()
    func signIn(credential: ASAuthorizationAppleIDCredential) throws
    func restoreSession() -> AuthSession?
    func validateSession(userID: String) async -> Bool
    func signOut()
}
```

### Launch behaviour

In `BirdieBuddyApp.init()`:
1. Call `AuthService.shared.restoreSession()` — populate `AppState.authSession` if token exists
2. Call `AuthService.shared.validateSession(userID:)` asynchronously — sign out if revoked

---

## UI Changes

### HomeView
- Top-right: avatar/initials button if signed in; "Sign In" text button if not
- Tapping the avatar opens `AccountView` (inline sheet)
- "Start Live Round" and "Join Round" — if tapped while signed out, show `SignInPromptSheet` first

### New screens

| Screen | Route | Description |
|---|---|---|
| `SignInView` | `.signIn` | Full-screen sign-in for unauthenticated entry points |
| `SignInPromptSheet` | (sheet) | Lightweight "Sign in to continue" prompt with Apple button |
| `AccountView` | (sheet from avatar) | Shows display name, email, sign-out button |

### AccountView

```
[Avatar / Initials]
Mike Schwimmer
m***@privaterelay.appleid.com

[Sign Out]
```

---

## Accessibility Identifiers

- `auth.signInWithAppleButton`
- `auth.signOutButton`
- `auth.accountAvatar`
- `auth.displayName`
- `auth.signInPromptSheet`

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| User cancels sign-in sheet | Silently dismiss — no error shown |
| Credential revoked on launch | Session cleared; user sees signed-out state on next open |
| Keychain write failure | Log error; proceed without persisting (user will need to sign in again next launch) |
| Backend rejects token | Sign out locally; show "Session expired, please sign in again" |

---

## Phased Delivery

**Phase 1 (this feature):**
- Sign in with Apple
- Keychain persistence
- Session restore on launch
- `AccountView` (sign out)
- Gated entry points for 013/014

**Phase 2 (with 013):**
- Identity token sent with backend API requests as `Authorization: Bearer <token>`
- Backend verifies token with Apple's public keys

---

## Prerequisites

None — this is a standalone feature with no blockers.

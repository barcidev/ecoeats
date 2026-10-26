---
kind: standard
---

# Hold the move to Home while a sign-in celebrates

## Goal

A sign-in screen can finish its celebration (the button's drawn check, then the achiote sweep born from it) before the app replaces it with Home. Today `app.dart` moves to Home the moment the session starts, so the login page is gone before its button can draw the check. A small hold in the session layer lets the screen ask the app to wait, with a limit so nobody is ever left on the sign-in screen.

## Out of scope

- Using the hold from login and registration, and the sweep born from the check (next change).
- Signing out and expired sessions, which keep moving to the welcome at once.

## Assumptions

- A1: The hold lives in `core/session` as a keep-alive `signInHoldProvider`: a screen calls `hold()` before sending credentials and `release()` once its celebration covers the app (or the attempt fails); the app awaits `wait()` before moving to Home.
  - impact: high
- A2: `wait()` never takes longer than 3 s from the moment the session starts, so a lost `release()` cannot strand anyone; the limit starts when the session changes, so a slow network does not eat into it.
- A3: Only the move to Home waits; the move to the welcome (sign-out, expired session) stays immediate.

## Acceptance criteria

- AC1: WHEN nothing holds THEN `wait()` completes at once; WHEN a screen holds THEN `wait()` completes when it releases; WHEN it never releases THEN `wait()` completes 3 s after it began.
- AC2: WHEN a session starts while a sign-in holds THEN the app stays on the sign-in screen until the release, and then moves to Home.
- AC3: WHEN a session starts with nothing held, or a session ends THEN the app moves as before, with no wait.

## Files

- create lib/core/session/sign_in_hold.dart — the hold and its provider
- modify lib/app.dart — await the hold before moving to Home
- modify test/app_test.dart — the app waits for a held sign-in

## Tasks

- [ ] T1: The sign-in hold, with tests in test/core/session/sign_in_hold_test.dart
  - files: lib/core/session/sign_in_hold.dart
  - ac: AC1
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/core/session test/core/session && fvm flutter analyze && fvm flutter test test/core/session
- [ ] T2: The app waits for a held sign-in before moving to Home
  - files: lib/app.dart, test/app_test.dart
  - ac: AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/app.dart test/app_test.dart && fvm flutter analyze && fvm flutter test

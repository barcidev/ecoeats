---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C4
---

# Login controller: credentials, 401, 400 and 429 with its retry deadline

## Goal

The login screen gets a `loginController` that signs in through the session, tells apart wrong credentials (401), field errors (400) and the rate limit (429, with the moment the next try is allowed), and never sends twice. The auth clock is unified with the one phase 0 put in the session, so every deadline in the app reads the same time.

## Out of scope

- The login screen, its shake, the morphing button and the sweep (C5).
- The copy of each error (C2).
- Navigating to Home: the screen does it when the controller reports success (C5).

## Assumptions

- A1: The controller signs in with `sessionController.login`, which stores the token and sets the session; the controller only tracks the attempt.
- A2: The API names the login fields `email` and `password`, so a 400's field errors are read by those keys.
- A3: Phase 0 has a `clockProvider` in `core/session/session_controller.dart`; the one C7 added in `features/auth/application/clock.dart` duplicates it, so recovery moves to the core one and the auth one is deleted.

## Acceptance criteria

- AC1: WHEN valid credentials are submitted THEN the state is submitting during the call and succeeded afterwards, and the session holds the user.
- AC2: WHEN the API answers 401 THEN the state keeps an unauthorized failure, is not succeeded, and a new submit is allowed.
- AC3: WHEN the API answers 400 with field errors THEN the state names which of email and password were rejected.
- AC4: WHEN the API answers 429 THEN the state keeps the failure and the moment `Retry-After` allows the next try; WHEN the user submits before it THEN nothing is sent; WHEN that moment passes THEN a submit is sent.
- AC5: WHEN a submit arrives while one is running THEN only one request is sent.
- AC6: WHEN the user dismisses an error THEN the failure is cleared, but the 429 wait stays until it ends.
- AC7: WHEN the recovery controller computes a deadline THEN it reads the core `clockProvider`, and the auth `clock.dart` no longer exists.

## Files

- create lib/features/auth/application/login_controller.dart — login state and controller
- modify lib/features/auth/application/recovery_controller.dart — read the core clock
- delete lib/features/auth/application/clock.dart — duplicate of the core clock

## Tasks

- [ ] T1: Use the core clock in recovery and delete the auth clock
  - files: lib/features/auth/application/recovery_controller.dart, lib/features/auth/application/clock.dart
  - ac: AC7
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features/auth/application/recovery_controller_test.dart
  - type: refactor
- [ ] T2: Login controller, with unit tests in test/features/auth/application/login_controller_test.dart
  - files: lib/features/auth/application/login_controller.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth

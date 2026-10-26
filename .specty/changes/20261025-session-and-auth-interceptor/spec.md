---
kind: standard
follows:
  - 20261025-auth-data-layer
---

# Session and auth interceptor

## Goal

The app keeps one session: the 24 h JWT is stored securely, restored at start (and dropped if it expired), and exposed by a keepAlive `sessionController` with login, register with auto-login, logout and a reaction to an expired token. Every authenticated request carries the Bearer token, and a 401 on an authenticated route ends the session and raises a signal the UI turns into a «session expired» toast.

## Out of scope

- The toast itself, the splash and the redirects of the guards (routes change).
- Theme and language preferences (agent A).

## Assumptions

- A1: The JWT carries `sub`, `email`, `role` and `exp`; the app decodes its payload without verifying the signature, which only the server can do.
  - impact: high
- A2: The first names typed at register are stored next to the token, keyed by email, so the greeting can say «Jorge» on later logins; login alone never knows the name.
- A3: The interceptor reads the token from the store at request time instead of watching the session, which avoids a dependency cycle between Dio and the session controller.
- A4: Requests to `/api/securities/*` never carry the Bearer token, and a 401 there (wrong password) does not end the session.

## Acceptance criteria

- AC1: WHEN a token's payload is decoded THEN its `sub`, `email`, `role` and `exp` are read; WHEN the token is malformed THEN decoding returns nothing.
- AC2: WHEN the app starts with a stored token that has not expired THEN the session is restored; WHEN it expired or is malformed THEN it is deleted and there is no session.
- AC3: WHEN login succeeds THEN the token is stored and the session holds the email, the expiry and the stored first names; WHEN it fails THEN the failure reaches the caller and there is still no session.
- AC4: WHEN register succeeds THEN the first names are stored and the user is logged in with the same credentials.
- AC5: WHEN the user logs out THEN the token is deleted and there is no session; WHEN an authenticated request answers 401 THEN the same happens and the expired signal is raised once.
- AC6: WHEN a request goes to an authenticated route THEN it carries `Authorization: Bearer <token>`; WHEN it goes to `/api/securities/*` THEN it carries none.

## Files

- create lib/core/session/token_store.dart — secure token and first-names storage
- create lib/core/session/jwt.dart — JWT payload decoding
- create lib/core/session/session.dart — Session model (freezed)
- create lib/core/session/session_controller.dart — session controller, expired signal and clock
- create lib/core/network/auth_interceptor.dart — Bearer header and 401 handling
- modify lib/core/network/dio_provider.dart — add the auth interceptor
- create test/core/session/jwt_test.dart — JWT tests
- create test/core/session/session_controller_test.dart — session tests
- create test/core/network/auth_interceptor_test.dart — interceptor tests

## Tasks

- [x] T1: JWT decoding, Session and token store
  - files: lib/core/session/jwt.dart, lib/core/session/session.dart, lib/core/session/token_store.dart, test/core/session/jwt_test.dart
  - ac: AC1
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/core
- [x] T2: Session controller
  - files: lib/core/session/session_controller.dart, test/core/session/session_controller_test.dart
  - ac: AC2, AC3, AC4, AC5
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/core
- [ ] T3: Auth interceptor
  - files: lib/core/network/auth_interceptor.dart, lib/core/network/dio_provider.dart, test/core/network/auth_interceptor_test.dart
  - ac: AC5, AC6
  - verify: fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test

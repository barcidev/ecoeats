---
kind: standard
follows:
  - 20261025-auth-and-profile-placeholders
---

# Router, guards and app shell

## Goal

The app runs end to end: `main.dart` keeps the native splash until the stored session is read, locks portrait, draws edge to edge, warms the API up and retries only transient failures; `app.dart` builds the router app with the light and dark themes, the active language and its Material localizations, a status bar that follows the theme, and the «session expired» toast; the router registers every route of the plan behind an `AuthGuard` and a `GuestGuard` and re-evaluates them when the session changes, so logging in lands on Home and logging out or an expired token goes back to the welcome.

## Out of scope

- Theme and language preferences (agent A); the app follows the system for both until then.
- Native splash, icons and platform folders (blocked native platforms change).

## Assumptions

- A1: The app widget lives in `lib/app.dart` and the router in `lib/router/`, instead of the plan's `lib/app/`, because `lib/app/app.dart`, `lib/app/router/` and `lib/main.dart` would be three modules for Specty's limit of two.
  - impact: high
- A2: `AuthGuard` uses `resolver.redirectUntil(AuthShellRoute())` and the router's `reevaluateListenable` follows whether there is a session, as the plan says; the redirect replaces the guarded page so back never returns to a private page after a logout.
- A3: `GuestGuard` lets a signed-in user nowhere near the auth routes: it sends them to Home.
- A4: The design gallery route exists only in debug builds.
- A5: The old smoke test is replaced by an app test, since `main.dart` no longer defines a widget.

## Acceptance criteria

- AC1: WHEN the app starts without a session THEN the welcome shows; WHEN it starts with one THEN Home shows.
- AC2: WHEN the user logs in from the login page THEN Home shows, and WHEN they log out THEN the welcome shows and back does not return to Home.
- AC3: WHEN the server rejects the token of the session THEN the welcome shows with the toast «Tu sesión venció. Entra de nuevo para seguir.».
- AC4: WHEN a signed-in user is sent to an auth route THEN they stay on Home; WHEN a guest is sent to a private route THEN they get the welcome.
- AC5: WHEN the device language is English THEN the app's texts and Material's are in English, and the router app uses the light theme in light mode and the dark one in dark mode.

## Files

- create lib/router/app_router.dart — routes, router and session listenable providers
- create lib/router/guards.dart — AuthGuard and GuestGuard
- create lib/app.dart — router app, themes, language, status bar and expired toast
- modify lib/main.dart — splash, orientation, edge to edge, warm-up, retry policy and translations
- delete test/smoke_test.dart — replaced by the app test
- create test/router/guards_test.dart — guard unit tests
- create test/app_test.dart — end-to-end navigation tests with fakes

## Tasks

- [x] T1: Guards
  - files: lib/router/guards.dart, test/router/guards_test.dart
  - ac: AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze lib/router test/router && fvm flutter test test/router
- [ ] T2: Router and app shell
  - files: lib/router/app_router.dart, lib/app.dart, lib/main.dart, test/smoke_test.dart, test/app_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test

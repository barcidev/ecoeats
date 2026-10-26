---
kind: standard
follows:
  - 20261025-translations-setup
---

# Auth and profile placeholders

## Goal

The auth flow and the profile exist as the plan's phase 0 placeholders, so the router can register them and agent A can replace them: an auth shell that nests its pages over a persistent background, a welcome with its two actions, a working minimal login (so the catalog can be reached and tested), register and recover stubs, a panel transition, and the `ProfileSheet.show` contract that Home's avatar calls, with the user's email, the session's remaining time and sign-out.

## Out of scope

- The real auth screens, controllers, validation and motion, and the profile's appearance and language settings (agent A).
- The router and guards (routes change).

## Assumptions

- A1: All five auth placeholder pages live in one file, `auth_pages.dart`, because each auth file weighs as a sensitive path; agent A splits them when it builds the real screens.
  - impact: high
- A2: The placeholders navigate by path (`/auth/login`, `/auth/register`, `/auth/recover`) so they do not depend on generated route classes.
- A3: After a successful login nothing navigates by hand: the session changes and the router's guards move the user to Home.
- A4: Sign-out in the placeholder sheet acts at once; the confirmation comes with agent A's sheet.

## Acceptance criteria

- AC1: WHEN the login placeholder is submitted with an email and a password THEN it calls the session's login with them and shows the button's loading state; WHEN login fails THEN a toast shows the failure's translated text.
- AC2: WHEN `ProfileSheet.show` opens with a session THEN the sheet shows the user's email and «Tu sesión vence en N h» from the session's expiry.
- AC3: WHEN sign-out is tapped in the sheet THEN the session's logout runs and the sheet closes.

## Files

- create lib/features/auth/presentation/auth_pages.dart — auth shell, welcome, login, register and recover placeholders
- create lib/features/auth/presentation/auth_transitions.dart — panel transition
- create lib/features/profile/presentation/profile_sheet.dart — ProfileSheet.show contract
- create test/features/profile/profile_sheet_test.dart — profile sheet and login placeholder tests

## Tasks

- [x] T1: Auth placeholders and panel transition
  - files: lib/features/auth/presentation/auth_pages.dart, lib/features/auth/presentation/auth_transitions.dart, test/features/profile/profile_sheet_test.dart
  - ac: AC1
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test test/features
- [x] T2: Profile sheet contract
  - files: lib/features/profile/presentation/profile_sheet.dart, test/features/profile/profile_sheet_test.dart
  - ac: AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test

## Closing

### Summary

The auth placeholders (shell, welcome, a working login, register and recover) and the panel transition exist, ready for the router and for agent A to replace. `ProfileSheet.show` shows the session and signs out.

### Deviations

- The login placeholder's test lives in `test/features/profile/profile_sheet_test.dart`, because a test under `test/features/auth/` would weigh as one more sensitive path.

### Decisions

- The five auth pages share `auth_pages.dart`; agent A splits them into one file per screen.
- A 401 on login reads «Correo o contraseña incorrectos.» instead of the generic unauthorized text.

### Follow-ups

- The routes change registers these pages under `/auth` with `authPanelTransition`.

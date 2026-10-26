---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C8
---

# The three recovery screens: masked email, countdowns, expired code back to step 2 and the drawn check

## Goal

A customer who forgot their password gets back in from the app: they ask for a code by email, type or paste it while the screen shows where it went and how long it lasts, choose a new password with the same live rules as registration, and see a check draw itself before returning to login with their email already filled in.

## Out of scope

- The recovery logic and the OTP field, done in C7 and used as they are.
- New copy: every text exists since C2; this slice only removes the unused `shell.photoCredit` key (C3's follow-up).

## Assumptions

- A1: The recover page renders `recoveryController`'s state: one screen per step (email, code, new password, done), crossfading forward; the back arrow is the controller's `back()` on the code and password steps and leaves the panel on the email step.
- A2: Login opens recovery and waits for its result: recovery pops with the email when it ends, and login fills that email in, clears the password and focuses it.
  - impact: high
- A3: The masked email keeps the first character of the local part and the whole domain (`j•••@gmail.com`), as the epic assumes.
- A4: A rejected code shakes the field with the design `Shake` (without its own haptic, since `OtpField` plays one) and the field clears; a resend gives a fresh field, keyed by the code's deadline.
- A5: The code counts as expired on screen as soon as its deadline passes, before any request; a code the reset no longer takes arrives as expired from the controller.
- A6: A resent code is confirmed with a toast, and the resend link becomes a countdown («Otro código en 0:42») until it is allowed again.

## Acceptance criteria

- AC1: WHEN step 1 is sent with a malformed email THEN the field says so and nothing is sent; WHEN the email does not exist THEN the field says there is no account with it; WHEN the server fails THEN its words appear and sending again works; WHEN the code is sent THEN step 2 opens with the email masked, such as `j•••@gmail.com`.
- AC2: WHEN step 2 is open THEN «Vence en mm:ss» counts down from 15:00, resending shows «Otro código en m:ss» until 60 s pass and then becomes a link; WHEN a new code is sent THEN a toast confirms it and the field starts empty.
- AC3: WHEN a code is rejected THEN the field shakes and clears and the attempts left are said in the right plural; WHEN all attempts are spent THEN the field locks and asks for a new code; WHEN the code expires, by time or because the reset says so, THEN step 2 shows that it expired and asks for a new one.
- AC4: WHEN a valid new password and its matching confirmation are saved THEN a check draws itself with «Listo.» and «Ir a entrar» returns to login with the email filled in; WHEN the confirmation differs or the password breaks a rule THEN its field says so and nothing is sent.
- AC5: WHEN reduced motion is on THEN the steps change by crossfade and the check appears already drawn.
- AC6: WHEN `fvm flutter test` runs THEN the recovery screen tests and the login handoff test pass.

## Files

- create lib/features/auth/presentation/recover_page.dart — the three recovery steps and the done screen
- modify lib/features/auth/presentation/auth_pages.dart — drop the recover placeholder, export the screen
- modify lib/features/auth/presentation/login_page.dart — wait for recovery's email and fill it in
- modify lib/i18n/es/auth.i18n.yaml — remove the unused photo credit
- modify lib/i18n/en/auth.i18n.yaml — remove the unused photo credit

## Tasks

- [ ] T1: Recovery screens, with widget tests in test/features/auth/presentation/recover_page_test.dart
  - files: lib/features/auth/presentation/recover_page.dart, lib/features/auth/presentation/auth_pages.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [ ] T2: Login fills in the email recovery returns, with a widget test in test/features/auth/presentation/login_page_test.dart
  - files: lib/features/auth/presentation/login_page.dart
  - ac: AC4, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [ ] T3: Remove the unused photo credit from the auth copy
  - files: lib/i18n/es/auth.i18n.yaml, lib/i18n/en/auth.i18n.yaml
  - ac: AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm flutter analyze && fvm flutter test
  - type: chore

## Risks

- R1: `recover_page.dart` holds four screens and a painter and could pass the 500-line limit. Mitigation: the steps share the panel pieces from `auth_panel.dart` and the file stays compact; if it nears the limit, the done screen moves out in a follow-up.

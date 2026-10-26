---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C7
---

# Recovery state machine and the OTP field, with unit and widget tests

## Goal

Password recovery has its logic ready before its screens: a `recoveryController` that walks the three steps (email, code, new password) as a freezed state machine, with the deadlines, attempts and errors the API imposes, and an `OtpField` that takes six digits by typing, pasting or autofill and reacts to a rejected code.

## Out of scope

- The recovery screens, the masked email and the drawn check (C8).
- The copy for each state (C2).
- The shake animation: the recover page wraps the field in the design system's `Shake` (C8), so the field does not duplicate it.

## Assumptions

- A1: The API behaves as its source says: `forgot-password` answers 404 for an unknown email and 5xx when the mail fails; `verify-otp` always answers 200 with `valid`; five wrong codes lock the current code; `reset-password` answers 400 without field errors when the code is invalid, expired or used, and 400 with field errors when the password breaks a rule.
- A2: Deadlines come from a `clockProvider` in `features/auth/application`, because `core/**` is frozen for the agents; tests override it. It can move to core when the agents are integrated.
- A3: The code's validity (15 minutes), the resend wait (60 s) and the five attempts are tracked on the device from the moment the code was sent; the server stays the judge, so a code it rejects is rejected whatever the local deadline says.
- A4: `OtpField` is a single hidden text input drawn as six boxes, so paste, the platform's one-time-code autofill, delete and screen readers behave as in any text field.
- A5: The shake of a rejected code lives in the page (C8), with the design `Shake` around the field; the field clears, plays the haptic and shows the error look.
  - impact: high

## Acceptance criteria

- AC1: WHEN a code is requested for an email THEN the machine moves to the code step with the normalized email, a validity deadline 15 minutes later, resend unlocked 60 s later and 5 attempts left; WHEN the email does not exist (404) or the server fails (5xx) THEN it stays on the email step with that failure, and asking again works.
- AC2: WHEN a complete code is verified and the API says it is valid THEN the machine moves to the new password step; WHEN the API says it is not THEN it stays on the code step marked rejected with one attempt less; WHEN the fifth code is rejected THEN the code is marked locked and no more codes are sent until a new one is requested.
- AC3: WHEN a code is verified at or after its deadline THEN the machine marks it expired without calling the API.
- AC4: WHEN a resend is asked before 60 s THEN nothing is sent; WHEN it is asked after THEN a new code is requested and the deadlines and attempts start over.
- AC5: WHEN the new password is accepted THEN the machine ends in done with the email; WHEN the reset answers 400 without field errors THEN it returns to the code step marked expired; WHEN it answers 400 with field errors THEN it stays on the password step with them.
- AC6: WHEN a step gets 429 THEN the state keeps the failure and the moment until which that step is blocked, from `Retry-After`.
- AC7: WHEN the user types digits into the OTP field THEN the boxes fill in order and the active box moves to the next one; WHEN the sixth digit arrives THEN the complete code is reported once.
- AC8: WHEN text is pasted or autofilled into the field THEN anything that is not a digit is dropped and the first six digits fill the boxes.
- AC9: WHEN the field is marked with an error THEN it clears, plays a haptic and shows the error look until the user types again; WHEN it is disabled THEN it takes no input.
- AC10: WHEN `fvm flutter test test/features/auth` runs THEN the recovery machine tests and the OTP field widget tests pass.

## Files

- create lib/features/auth/application/clock.dart — injectable clock for every auth deadline
- create lib/features/auth/application/recovery_controller.dart — freezed recovery states and the controller that walks them
- create lib/features/auth/presentation/widgets/otp_field.dart — the six-box code field

## Tasks

- [x] T1: Clock and recovery state machine, with unit tests in test/features/auth/application/recovery_controller_test.dart
  - files: lib/features/auth/application/clock.dart, lib/features/auth/application/recovery_controller.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6, AC10
  - verify: fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth/application
- [x] T2: OTP field, with widget tests in test/features/auth/presentation/widgets/otp_field_test.dart
  - files: lib/features/auth/presentation/widgets/otp_field.dart
  - ac: AC7, AC8, AC9, AC10
  - verify: fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth

## Risks

- R1: The device clock and the server's disagree, so a code may still be valid when the local deadline says it expired, or the reverse. Mitigation: the local deadline only blocks the obvious case; any server rejection wins.

---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C6
---

# Two-step registration with the live password checklist, errors routed to their step and field, and automatic sign-in

## Goal

A new customer creates an account in two short steps, who they are (first names, last names, document) and how they will sign in (email, password), with a live checklist that shows the password's rules as they type. Whatever the API refuses lands on the step and field it is about, and a created account signs in on its own and keeps the first names for Home's greeting.

## Out of scope

- Home's greeting itself (agent B reads the stored first names from the session).
- Recovery screens (C8), which will reuse the checklist.

## Assumptions

- A1: Signing up goes through `sessionController.register`, which creates the account, stores the first names and logs in with the same credentials (phase 0); the controller only tracks the attempt and the step.
- A2: The API names a 400's fields by their JSON keys (`numero_documento`, `nombres`, `apellidos`, `correo`, `password`), as its error handler does, and a 409 says in its message whether the email or the document collided, which phase 0 maps to `ConflictField`.
- A3: A 400 field message is the server's own text only when the app is in Spanish; in English the field shows the app's generic «check this» words, as the plan asks for server messages.
- A4: Moving between steps keeps what was typed; the back arrow on step 2 returns to step 1, and on step 1 it leaves the panel.
- A5: The checklist is its own widget so recovery's new password step uses it too; the byte hint only appears when the password nears or passes the limit.
- A6: A success plays the same achiote sweep as login and asks the platform to save the new credentials.

## Acceptance criteria

- AC1: WHEN step 1 is continued with blank or too long first names, last names or document THEN each field shows its message, the form shakes with a haptic and step 2 does not open; WHEN they are valid THEN step 2 opens and shows «Paso 2 de 2».
- AC2: WHEN the user types a password in step 2 THEN a checklist shows live whether it has at least 6 characters and fits the byte limit; WHEN it passes 72 bytes (for example 40 «ñ») THEN the byte rule fails, its hint shows and the account cannot be created.
- AC3: WHEN the API answers 409 for the document or 400 about a step 1 field THEN the form returns to step 1 and that field shows its message; WHEN it answers 409 for the email or 400 about the email or password THEN step 2 shows it on that field; in both cases the form shakes.
- AC4: WHEN registration succeeds THEN the user is signed in, the first names are stored for the greeting, and the achiote sweep hands over to Home.
- AC5: WHEN the API answers 429 THEN the button counts down «Intenta en m:ss» and works again at zero; WHEN the request fails otherwise THEN that failure's words appear under the form.
- AC6: WHEN `fvm flutter test` runs THEN the register controller, checklist and registration screen tests pass.

## Files

- create lib/features/auth/application/register_controller.dart — registration state, step and controller
- create lib/features/auth/presentation/widgets/password_checklist.dart — live password rules
- create lib/features/auth/presentation/register_page.dart — the two-step registration screen
- modify lib/features/auth/presentation/auth_pages.dart — drop the register placeholder, export the screen

## Tasks

- [x] T1: Register controller, with unit tests in test/features/auth/application/register_controller_test.dart
  - files: lib/features/auth/application/register_controller.dart
  - ac: AC3, AC4, AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth/application
- [x] T2: Password checklist, with widget tests in test/features/auth/presentation/widgets/password_checklist_test.dart
  - files: lib/features/auth/presentation/widgets/password_checklist.dart
  - ac: AC2
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [x] T3: Two-step registration screen, with widget tests in test/features/auth/presentation/register_page_test.dart
  - files: lib/features/auth/presentation/register_page.dart, lib/features/auth/presentation/auth_pages.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test

## Risks

- R1: The account can be created and the automatic login then fail (a lost connection between both calls); trying again would answer 409 for the email. Mitigation: the 409 message on the email field is clear, and the user can sign in from login; the closing records it.

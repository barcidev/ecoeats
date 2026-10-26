---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C5
---

# Login screen: validation, autofill, error states with shake and haptic, morphing button and achiote sweep to Home, with a widget test

## Goal

The login placeholder becomes the real screen: it checks the fields before sending, works with the platform's saved passwords, says in the app's own words what went wrong (wrong credentials, field errors, too many tries with a countdown), shakes with a haptic when it refuses, morphs its button into a spinner while it works, and celebrates a successful sign-in with an achiote sweep that hands over to Home.

## Out of scope

- Registration and recovery screens (C6, C8); they keep their placeholders, now on the shared panel.
- Changing how the app moves to Home after a sign-in: `app.dart` keeps doing it when the session changes.

## Assumptions

- A1: Field messages appear after the first submit and then follow the typing, so nobody is scolded while still typing for the first time.
- A2: The sweep is drawn in the app's root overlay, above the navigator, because the session change makes `app.dart` replace the auth stack with Home at once; it starts when `loginController` reports success, grows from the button, and lifts away after Home is beneath it.
  - impact: high
- A3: The sheet panel and a countdown text move to `widgets/auth_panel.dart`, so registration and recovery reuse them; `auth_pages.dart` keeps exporting the pages, so the router still finds them.
- A4: Only a sign-in the API refuses (401 or 400) or a form the client refuses shakes; network and server failures show their words without shaking, since nothing the user typed was wrong.
- A5: Once the platform has credentials it can save, a successful sign-in calls `TextInput.finishAutofillContext()` so iOS and Android offer to store them.

## Acceptance criteria

- AC1: WHEN login is submitted with an empty or malformed email or an empty password THEN each field shows its message, the form shakes with a haptic and no request is sent; WHEN the user then fixes a field THEN its message updates while typing.
- AC2: WHEN the screen opens THEN the email field offers email and username autofill and the password field offers password autofill, and the password can be shown and hidden.
- AC3: WHEN the API answers 401 THEN «Correo o contraseña incorrectos.» appears under the form and the form shakes with a haptic; WHEN it answers 400 with field errors THEN each named field shows its message; WHEN the request fails otherwise THEN that failure's own words appear.
- AC4: WHEN the API answers 429 THEN the button is disabled and reads «Intenta en m:ss», counting down each second, and works again at zero.
- AC5: WHEN the request is running THEN the button shows its spinner; WHEN it succeeds THEN an achiote disc grows from the button over the whole app and then fades, with Home beneath.
- AC6: WHEN the user taps «¿Olvidaste tu contraseña?» THEN recovery opens over login; WHEN they tap «Crear una» THEN registration takes login's place.
- AC7: WHEN reduced motion is on THEN the form does not move when it refuses (the haptic stays) and there is no sweep.
- AC8: WHEN `fvm flutter test` runs THEN the login screen and sweep widget tests pass, together with phase 0's login tests.

## Files

- create lib/features/auth/presentation/widgets/auth_panel.dart — the sheet every auth panel sits in, and the countdown text
- create lib/features/auth/presentation/widgets/achiote_sweep.dart — the success sweep over the app
- create lib/features/auth/presentation/login_page.dart — the login screen
- modify lib/features/auth/presentation/auth_pages.dart — drop the login placeholder and the private panel, export the login page

## Tasks

- [ ] T1: Move the sheet panel to its own file and add the countdown text, with widget tests in test/features/auth/presentation/widgets/auth_panel_test.dart
  - files: lib/features/auth/presentation/widgets/auth_panel.dart, lib/features/auth/presentation/auth_pages.dart
  - ac: AC4
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test
- [ ] T2: Achiote sweep, with widget tests in test/features/auth/presentation/widgets/achiote_sweep_test.dart
  - files: lib/features/auth/presentation/widgets/achiote_sweep.dart
  - ac: AC5, AC7
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth
- [ ] T3: Login screen, with widget tests in test/features/auth/presentation/login_page_test.dart
  - files: lib/features/auth/presentation/login_page.dart, lib/features/auth/presentation/auth_pages.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test

## Risks

- R1: If the sweep starts after the login page has left the tree, it has no context to draw from. Mitigation: the login controller reports success before the router rebuilds (the rebuild waits for the next frame), and the sweep only needs the overlay and the button's position, taken at that moment.

---
kind: epic
---

# Access and account (agent A)

## Goal

A customer can enter EcoEats the way the plan describes for agent A: a welcome over a living photo backdrop, login, two-step registration with automatic sign-in, and three-step password recovery with an emailed code, all with designed error states and motion. Once inside, the profile sheet shows who they are and when the session ends, lets them pick appearance and language (persisted), and signs them out.

## Out of scope

- The dish catalog, Home, detail and Discover (agents B and C); Home only receives the stored first name for its greeting.
- The premium versions of the shared design widgets (agent C); this epic uses their phase 0 contracts as they are.
- Phase 0 itself: core (network, session, failures), auth data layer, router and guards, i18n setup and the design widget contracts.
- Editing the profile, deleting the account, social login and keeping a session beyond the token's 24 h, which the API does not support.

## Assumptions

- A1: Slices start only when the phase 0 pieces they use are on `main`: C1 needs nothing beyond the current `main`; C2 needs the i18n setup; C3 to C9 need the router, the design widget contracts, `sessionController`, `AppFailure` and the auth repository. Each slice's own spec is written when it starts, against what `main` has by then.
  - impact: high
- A2: Files outside agent A's paths (`app.dart`, the router, `core/**`, `design/**`, `pubspec.yaml`) change only through a scope request that is small and additive, and each one is noted in the slice's closing; the plan treats them as frozen for the parallel agents.
  - impact: high
- A3: Validators are pure Dart and return typed reasons, not text; the screens turn each reason into a translated message. A password is valid with at least 6 characters and at most 72 bytes in UTF-8, as the API's bcrypt limit requires.
- A4: Every countdown (429 retry, 15-minute code validity, 60 s resend) is stored in state as a deadline taken from an injectable clock, and widgets only render the remaining time. That keeps them testable without real waiting.
- A5: The recovery flow is one freezed sealed state per step (email, code, new password, done). A code rejected by the server stays on the code step; a code that expired, by its deadline or because the reset says so, returns to the code step with a new request available.
- A6: The login success sweep belongs to auth: an achiote circle grows from the button over the screen and then the router replaces the stack with Home. If the phase 0 `EcoButton` already exposes a success expansion, the sweep uses it instead.
- A7: The three welcome photos are dishes from the API seed, bundled as assets with their Unsplash credit. If phase 0 has not added them, C3 adds them and requests the `pubspec.yaml` asset entry.
- A8: Appearance and language persist in `shared_preferences`. «Sistema» follows the device language when it is Spanish or English and falls back to Spanish; each language is listed in its own name (Español, English).
- A9: The masked email keeps the first character of the local part and the whole domain, for example `j•••@gmail.com`.
- A10: The session expiry shown in the profile comes from the token's `exp` claim, which phase 0 keeps in `Session`.

## Acceptance criteria

- AC1: WHEN the user moves between welcome, login, register and recover THEN the same full-bleed backdrop keeps running without restarting: three photos with a slow Ken Burns pan, a crossfade between them, a scrim and paper grain.
- AC2: WHEN a panel opens over the welcome THEN it rises as a stacked sheet while the photo scales to 0.94 and darkens; WHEN the user goes back THEN the panel lowers and the photo returns to full size and brightness.
- AC3: WHEN the welcome opens THEN the logo draws itself as a plate rim, the headline «Comida colombiana, sin afán.» reveals line by line under a mask, and «Entrar» and «Crear cuenta» lead to login and registration.
- AC4: WHEN login is submitted with an invalid email or an empty password THEN the field shows its error and no request is sent; WHEN the platform offers saved credentials THEN the email and password fields accept autofill.
- AC5: WHEN login returns 401 THEN «Correo o contraseña incorrectos.» appears and the form shakes with a haptic; WHEN it returns 400 with field errors THEN each error appears on its field; WHEN it returns 429 THEN the button is disabled and shows «Intenta en m:ss», counting down from `Retry-After` and enabling again at zero.
- AC6: WHEN login is in flight THEN the button morphs into a spinner; WHEN it succeeds THEN an achiote sweep covers the screen from the button and the app lands on Home with the auth screens removed from the stack.
- AC7: WHEN the user types a password in registration step 2 THEN a checklist shows live whether it has at least 6 characters and fits in 72 bytes; WHEN it exceeds 72 bytes, for example with emoji or many accented letters, THEN the account cannot be created and the byte rule is marked as failing.
- AC8: WHEN registration returns 409 for the email or the document, or 400 with field errors, THEN the form goes back to the step that holds that field and shows the error on it.
- AC9: WHEN registration succeeds THEN the app signs in on its own, stores the first names, and Home's greeting can use them («Buenas tardes, Jorge.»).
- AC10: WHEN recovery step 1 is submitted THEN an unknown email shows that it does not exist, a 503 offers a retry, and success opens step 2 with the masked email.
- AC11: WHEN the user types or pastes a 6-digit code THEN the boxes fill and advance one by one, a paste fills all six, and a complete code is verified without pressing a button; WHEN the code is rejected THEN the boxes shake with a haptic and clear.
- AC12: WHEN step 2 is open THEN «Vence en mm:ss» counts down from 15:00 and resending unlocks after 60 s; WHEN the code expires, by time or because the reset reports it, THEN the flow is on step 2 with a new code available.
- AC13: WHEN a valid new password and its matching confirmation are accepted THEN a check draws itself and the flow returns to login with the email filled in.
- AC14: WHEN the profile sheet opens THEN it shows the first name when known, the email, and «Tu sesión vence en N h» from the token expiry.
- AC15: WHEN the user picks Sistema, Claro or Oscuro, or Sistema, Español or English, THEN the app changes at once and keeps the choice after a restart.
- AC16: WHEN the user taps «Cerrar sesión» and confirms THEN the session is cleared and the welcome appears; WHEN they cancel THEN nothing changes.
- AC17: WHEN reduced motion is on THEN the Ken Burns pan, the stacked-sheet transition, the shakes and the sweep become crossfades or are skipped.
- AC18: WHEN the language is English THEN every auth and profile text appears in English written in its own voice, not translated word for word, and no raw server message (Spanish only) is shown.
- AC19: WHEN `fvm flutter test` runs THEN tests for the validators, the recovery state machine, the login screen, the OTP field and the theme and locale controllers pass.

## Design

- `lib/features/auth/application/`: `validators.dart` (pure), `login_controller.dart`, `register_controller.dart`, `recovery_controller.dart` with its freezed state.
- `lib/features/auth/presentation/`: `auth_shell_page.dart` (nested router over the backdrop), `auth_transitions.dart` (stacked sheet), the welcome, login, register and recover pages, and `widgets/` for the backdrop, the shared panel, the OTP field, the password checklist, the countdown text, the success sweep and the drawn check.
- `lib/features/profile/`: `application/theme_mode_controller.dart` and `locale_controller.dart`, `presentation/profile_sheet.dart`.
- `lib/i18n/{es,en}/auth.i18n.yaml` and `profile.i18n.yaml`.
- The size limits (`**/auth/**` is sensitive, so each auth file weighs 4) leave room for about four auth files per slice. That is why some screens split their logic and their UI into two slices. Tests live next to their code in `test/` and enter each slice as implicit tests.

## Slices

- C1: Input validators: email, names, document, password (6 characters to 72 bytes, with checklist rules) and 6-digit code, with unit tests
  - ac: AC4, AC7, AC19
- C2: Auth and profile copy in Spanish and English
  - ac: AC18
- C3: Auth shell with the living backdrop and the stacked-sheet transition, and the welcome
  - ac: AC1, AC2, AC3, AC17
  - depends: C2
- C4: Login controller: credentials, 401, 400 and 429 with its retry deadline
  - ac: AC5
  - depends: C1
- C5: Login screen: validation, autofill, error states with shake and haptic, morphing button and achiote sweep to Home, with a widget test
  - ac: AC4, AC5, AC6, AC17, AC19
  - depends: C3, C4
- C6: Two-step registration with the live password checklist, errors routed to their step and field, and automatic sign-in
  - ac: AC7, AC8, AC9
  - depends: C1, C3
- C7: Recovery state machine and the OTP field, with unit and widget tests
  - ac: AC11, AC12, AC19
  - depends: C1
- C8: The three recovery screens: masked email, countdowns, expired code back to step 2 and the drawn check
  - ac: AC10, AC12, AC13
  - depends: C3, C7
- C9: Profile sheet with session data, persisted appearance and language, and sign-out with confirmation, with controller tests
  - ac: AC14, AC15, AC16, AC19
  - depends: C2

## Risks

- R1: Phase 0 lands later than this epic or its contracts differ from the plan. Mitigation: each slice writes its spec when it starts, against `main`; C1 has no dependency, so work can start now.
- R2: A slice finds it needs a file it did not list, and `**/auth/**` makes every addition weigh more. Mitigation: a scope request with its reason, decided in delegated mode and recorded in the audit; if a slice would exceed size L, it splits.
- R3: The OTP flow needs a real inbox, and repeated logins hit the 429 limit. Mitigation: unit and widget tests use a fake repository; the real check uses the single shared test account, and the user runs the OTP flow with their own email.

## Closing

### Summary

Agent A's access and account are done in nine closed slices. A guest lands on a welcome over a living backdrop (three seed dishes with Ken Burns and crossfade, scrim and grain) that never restarts between auth pages; panels rise as stacked sheets while the photo steps back to 0.94 and darkens. The welcome draws its logo, reveals its headline under a mask and offers its two actions. Login checks its fields, works with saved credentials, says what the API refused in the app's words with a shake and a haptic, counts down a 429 on its button and sweeps into Home in achiote. Registration takes two steps with a live password checklist (6 characters to 72 bytes), sends each refusal to its step and field, signs in on its own and keeps the first names for the greeting. Recovery walks a freezed state machine through email, an emailed code (OTP field with paste and autofill, 15-minute and 60 s countdowns, masked email, rejected, locked and expired codes) and a new password, then draws a check and hands the email back to login. The profile sheet shows the session, persists appearance and language (applied before the first frame) and confirms the sign-out. Everything reads in Spanish and English, and reduced motion turns the motion into crossfades. The suite grew from 45 to 326 tests and `flutter analyze` is clean.

### Deviations

- Two of phase 0's tests changed with the user's approval: `test/app_test.dart` finds the welcome headline by its semantics label, and the profile sign-out test confirms first.
- The welcome stayed inside C3 instead of a slice of its own: the epic's spec is locked while it is implemented, so C3 kept the shell, backdrop, welcome and photos within size L by keeping them in `auth_pages.dart`, which later slices emptied as each page moved to its own file.
- The photo credit lives in `assets/photos/CREDITS.md` (Unsplash, with the source URLs) instead of on screen, because the seed does not record the photographers.

### Decisions

- Pages navigate inside the auth shell with relative paths; absolute ones pushed a second shell (a phase 0 bug, fixed in C3).
- The achiote sweep lives in the root overlay, since the app replaces the auth stack with Home the moment the session changes.
- The backdrop runs two rounds after a still intro and then rests, sparing the GPU and letting the app tests settle.
- The duplicate auth clock was dropped for the core `clockProvider`, which every countdown reads.

### Follow-ups

- No native platforms exist yet, so every visual check was made on golden renders; a pass on simulators (iPhone 17 Pro, SE and Pixel 9) and the real OTP flow with a real inbox are pending.
- Making the auth child routes non-opaque in `app_router.dart` would keep the stacked-sheet look after the transition ends.
- `EcoTextField` could take `textCapitalization` for names (agent C).
- The show/hide password toggle repeats in three screens and could become a shared piece.
- On the recovery code step, the expiry countdown could stay visible next to a rejected code's message.
- `Validators.normalizeEmail` duplicates `normalizeEmail` in `auth_repository.dart`.

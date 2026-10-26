---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C9
---

# Profile sheet with session data, persisted appearance and language, and sign-out with confirmation, with controller tests

## Goal

The profile sheet that Home's avatar opens becomes the real one: it shows who is signed in and when the session ends, lets the customer choose the appearance (system, light, dark) and the language (system, Español, English) with an immediate change that survives a restart, and signs out only after a confirmation.

## Out of scope

- Editing the profile or deleting the account, which the API does not support.
- How Home opens the sheet: `ProfileSheet.show` keeps its signature.

## Assumptions

- A1: Both choices persist in `shared_preferences` (keys `profile.appearance` and `profile.language`), read through keep-alive async controllers; `main` waits for both before the first frame, as it already waits for the session, so the app never flashes the wrong theme or language.
  - impact: high
- A2: «Sistema» follows the device: the theme mode becomes `ThemeMode.system`, and the language goes back to slang's device locale, which falls back to Spanish when the device is in another language.
- A3: The language changes through `LocaleSettings`, which `TranslationProvider` and the per-language formatters already follow; nothing else needs to know.
- A4: The sign-out confirmation happens inside the sheet: the button turns into the question with «Cancelar» and «Cerrar sesión», so no dialog stacks over the sheet.
- A5: The session's remaining time shows in whole hours, and as «menos de una hora» below one hour.
- A6: Phase 0's test that signed out with one tap now confirms first; the user approved changing it.

## Acceptance criteria

- AC1: WHEN the sheet opens with a session THEN it shows the first names when known, the email, and «Tu sesión vence en N h», or that it ends in less than an hour.
- AC2: WHEN the user picks Sistema, Claro or Oscuro THEN the app's theme changes at once; WHEN the app starts again THEN the same choice is applied before the first frame.
- AC3: WHEN the user picks Sistema, Español or English THEN every text changes language at once; WHEN the app starts again THEN the same choice is applied before the first frame; the languages are listed in their own names.
- AC4: WHEN the user taps «Cerrar sesión» THEN the sheet asks for confirmation; WHEN they confirm THEN the session ends and the sheet closes; WHEN they cancel THEN nothing changes.
- AC5: WHEN `fvm flutter test` runs THEN the theme and locale controller tests and the profile sheet tests pass.

## Files

- create lib/features/profile/application/theme_mode_controller.dart — persisted appearance choice
- create lib/features/profile/application/locale_controller.dart — persisted language choice applied through slang
- modify lib/features/profile/presentation/profile_sheet.dart — session data, appearance and language choices, confirmed sign-out
- modify lib/app.dart — follow the chosen theme mode
- modify lib/main.dart — apply the stored choices before the first frame
- modify test/features/profile/profile_sheet_test.dart — sign-out now confirms first; new sheet tests

## Tasks

- [x] T1: Theme mode and locale controllers, with unit tests in test/features/profile/application/
  - files: lib/features/profile/application/theme_mode_controller.dart, lib/features/profile/application/locale_controller.dart
  - ac: AC2, AC3, AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/profile test/features/profile && fvm flutter analyze && fvm flutter test test/features/profile
- [ ] T2: The app follows the chosen theme and applies both choices before its first frame
  - files: lib/app.dart, lib/main.dart
  - ac: AC2, AC3
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/app.dart lib/main.dart && fvm flutter analyze && fvm flutter test
- [ ] T3: The real profile sheet, with widget tests in test/features/profile/profile_sheet_test.dart
  - files: lib/features/profile/presentation/profile_sheet.dart, test/features/profile/profile_sheet_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/profile test/features/profile && fvm flutter analyze && fvm flutter test

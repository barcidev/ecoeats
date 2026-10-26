---
kind: standard
epic: 20261025-access-and-account-agent-a
slice: C3
---

# Auth shell with the living backdrop and the stacked-sheet transition, and the welcome

## Goal

The first thing a guest sees feels like the product: three Colombian dishes fill the screen behind every auth page, slowly zooming and crossfading under a scrim and paper grain, and that backdrop never restarts between pages. Panels rise over it as stacked sheets while the photo steps back, and the welcome draws its logo, reveals its headline and offers its two actions.

## Out of scope

- The real login, registration and recovery screens (C5, C6, C8); their placeholders only take the sheet shape.
- The achiote sweep after login (C5).
- Showing photographer names on screen (see A1).

## Assumptions

- A1: The photos are the seed images of Ajiaco Santafereño, Sancocho de Gallina and Arroz Atollado Valluno, cropped to 1000×2000 and bundled under `assets/photos/`. The seed does not record photographers and the Unsplash license does not require attribution, so the credit (source URLs and license) lives in `assets/photos/CREDITS.md` instead of on screen; the `shell.photoCredit` key stays unused until a slice that edits the copy removes it.
  - impact: high
- A2: The shell, the backdrop and the welcome stay in `auth_pages.dart` next to the placeholders, as phase 0 did, because each auth file weighs 4 in the size; later slices move each page out as they replace it.
- A3: The shell knows a panel is open from its nested router's page count, and the photo's depth follows with an implicit animation of the panel's duration and curve.
- A4: Status bar icons are light over the shell (a top scrim keeps the photo dark there); the navigation bar's follow the theme, over the paper that the bottom scrim fades into.
- A5: Pages keep navigating by path, as the phase 0 placeholders do, so they do not import the generated routes.

## Acceptance criteria

- AC1: WHEN the auth shell is shown THEN three bundled photos fill the screen behind every auth page, each slowly zooming and panning and then crossfading into the next, under a scrim and paper grain.
- AC2: WHEN the user goes from the welcome to login and back THEN the backdrop is the same widget state all along: it neither restarts nor flashes.
- AC3: WHEN a panel opens THEN it rises from the bottom as a sheet while the photo scales to 0.94, rounds its corners and darkens; WHEN a panel opens over another THEN the one below steps back behind it; WHEN the user goes back THEN each one returns to its place.
- AC4: WHEN the welcome opens THEN the logo draws its plate rim, the headline «Comida colombiana, sin afán.» reveals line by line under a mask, and then the subline and the «Entrar» and «Crear cuenta» actions appear; «Entrar» opens login and «Crear cuenta» opens registration.
- AC5: WHEN reduced motion is on THEN the photos neither zoom nor pan, panels and the photo change by crossfade without scaling, and the welcome shows at once without its intro.
- AC6: WHEN `fvm flutter test test/features/auth/presentation` runs THEN the shell and welcome widget tests pass.

## Files

- create assets/photos/** — the three welcome photos and their credits
- modify pubspec.yaml — declare the photos as assets
- modify lib/features/auth/presentation/auth_pages.dart — shell with the living backdrop, the welcome and the sheet-shaped panel
- modify lib/features/auth/presentation/auth_transitions.dart — stacked-sheet panel transition

## Tasks

- [x] T1: Bundle the three welcome photos with their credits
  - files: assets/photos/**, pubspec.yaml
  - ac: AC1
  - verify: fvm flutter pub get && test -f assets/photos/ajiaco.jpg && test -f assets/photos/sancocho.jpg && test -f assets/photos/arroz_atollado.jpg
  - type: chore
- [ ] T2: Living backdrop, persistent shell and stacked-sheet transition, with widget tests in test/features/auth/presentation/auth_shell_test.dart
  - files: lib/features/auth/presentation/auth_pages.dart, lib/features/auth/presentation/auth_transitions.dart
  - ac: AC1, AC2, AC3, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth/presentation
- [ ] T3: The welcome's intro and actions, with widget tests in test/features/auth/presentation/auth_shell_test.dart
  - files: lib/features/auth/presentation/auth_pages.dart
  - ac: AC4, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test

## Risks

- R1: Three full-screen photos cost memory and a decode on first show. Mitigation: they are decoded at the screen's width, precached when the shell opens, and only two are painted at a time.
- R2: An endless Ken Burns animation never lets a widget test settle. Mitigation: shell tests pump fixed durations instead of settling.

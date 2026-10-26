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
- [x] T2: Living backdrop, persistent shell and stacked-sheet transition, with widget tests in test/features/auth/presentation/auth_shell_test.dart
  - files: lib/features/auth/presentation/auth_pages.dart, lib/features/auth/presentation/auth_transitions.dart
  - ac: AC1, AC2, AC3, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test test/features/auth/presentation
- [x] T3: The welcome's intro and actions, with widget tests in test/features/auth/presentation/auth_shell_test.dart
  - files: lib/features/auth/presentation/auth_pages.dart
  - ac: AC4, AC5, AC6
  - verify: fvm dart run slang && fvm dart run build_runner build -d && fvm dart format --output=none --set-exit-if-changed lib/features/auth test/features/auth && fvm flutter analyze && fvm flutter test

## Risks

- R1: Three full-screen photos cost memory and a decode on first show. Mitigation: they are decoded at the screen's width, precached when the shell opens, and only two are painted at a time.
- R2: An endless Ken Burns animation never lets a widget test settle. Mitigation: shell tests pump fixed durations instead of settling.

## Closing

### Summary

The auth shell hosts its pages over a living backdrop: three seed photos (Ajiaco, Sancocho, Arroz atollado) bundled under `assets/photos/`, each zooming and drifting for 7 s and then crossfading into the next, under a top scrim, a fade into paper at the bottom and paper grain. The backdrop's state survives every page change, and while a panel is open the photo scales to 0.94, rounds its corners and darkens. Panels rise from the bottom as sheets, and the page beneath steps back (the welcome fades, a panel shrinks and lifts). The welcome plays one intro: the mark draws its plate rim next to the wordmark, the headline rises line by line under a mask, then the subline and the two actions arrive. Reduced motion keeps the photos still, turns the transitions into crossfades and shows the welcome at once. 8 widget tests; the whole suite (233 tests) and `flutter analyze` pass.

### Deviations

- `test/app_test.dart` (phase 0) found the headline as a single `Text`; with the line-by-line reveal it is two. With the user's approval its lookups now use the headline's semantics label, which still asserts that the whole headline is on screen.
- The welcome had navigated with absolute paths (`/auth/login`), which pushed a second auth shell on the root router and restarted the backdrop; it now pushes relative paths (`login`, `register`) inside the shell.

### Decisions

- The backdrop runs two rounds (about 42 s) and then rests on the first photo, and it starts drifting only after the welcome's intro. That is one movement at a time and no endless GPU work on an idle screen, and it also lets the app tests settle before the 3 s session-expired toast leaves.
- Photos are decoded at the screen's width plus the zoom margin (`ResizeImage`) and precached when the shell opens; both the current and the next photo stay in the tree under keyed opacities, so the handover never flashes.
- After a render review in light and dark: the bottom scrim reaches 90 % paper at the headline's height, the top scrim darkens to 55 % for the status bar and the mark, and the panels use `raised` so a sheet stands out from the darkened photo in dark mode.
- The shell reads the open panel from the nested router's `pageCount`, so the photo's depth follows pushes and pops without touching the router.

### Follow-ups

- `auth_pages.dart` has 491 code lines, close to the 500 limit: C5, C6 and C8 must move their page out of it before adding code, and the shell and welcome can move to their own files with them.
- `shell.photoCredit` is unused (the credit lives in `assets/photos/CREDITS.md`); a slice that edits the auth copy should remove it.
- With the auth child routes opaque (as the router declares them), the panel beneath a new sheet stops painting once the transition ends, so the stacked look lasts only during the transition. Making those routes non-opaque in `app_router.dart` would keep it.
- Visual review was done on golden renders, since the repository has no native platforms yet; a check on a simulator is still pending.

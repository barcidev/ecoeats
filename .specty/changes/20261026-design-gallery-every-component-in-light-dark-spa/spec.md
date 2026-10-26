---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C10
---

# Design gallery: every component in light, dark, Spanish and English, debug only

## Goal

Visual QA gets one place to look at the whole design system. In debug builds, the gallery shows every design component with real app copy, and it switches between light and dark and between Spanish and English on the spot. Motion pieces can be replayed: the morphing button, the drawn mark, the masked headline, the shake and the toasts. A screenshot script renders the gallery and Discover in the four combinations with the real fonts, so a reviewer can check them without a device.

## Out of scope

- How to open the gallery from the app's screens. It stays a debug-only route (`/_gallery`), as phase 0 registered it.
- Screenshots on a device: they need a signed-in session (the shared test account), so the user takes them.

## Assumptions

- A1: The gallery switches language through `LocaleSettings` and puts back the language it found when it closes. Its theme switch is local to the gallery, through a `Theme` override, so it does not touch the user's stored appearance.
  - impact: high
- A2: The gallery's copy comes from the existing namespaces (common, errors, auth, dishes, discover, profile), so switching language shows real translations. Only the section names, which are for designers, stay in English.
- A3: The screenshot script is a test outside `test/` (`tool/qa/screens_test.dart`), run on purpose. The regular test run never writes files. It loads Fraunces, Instrument Sans and Phosphor from their files, and writes PNGs to `build/qa/`, which git ignores. Photos show their designed placeholder, since tests have no network.
- A4: The gallery is a long scroll of sections, with the language and theme pills pinned at the top. Each motion demo has its own replay control.

## Acceptance criteria

- AC1: WHEN the gallery opens in a debug build THEN it shows, in sections: type, buttons (every variant, disabled, and a loading → success → idle demo), fields (resting, with error, obscured), selection (pills and fractional stars), feedback (toasts of each tone and a shake), media (dish placeholders), loading (spinners, skeletons, the drawn mark), drawings (every plate detail), states (every kind, with a running 429 countdown), motion (masked headline) and paper grain.
- AC2: WHEN a language pill is picked THEN the gallery's copy switches between Spanish and English; WHEN a theme pill is picked THEN the gallery switches between light and dark; WHEN the gallery closes THEN the app is back in the language it had.
- AC3: WHEN `fvm flutter test tool/qa/screens_test.dart` runs THEN `build/qa/` holds PNGs of the gallery and of Discover in light and dark, Spanish and English, set in the real fonts.
- AC4: WHEN `fvm flutter test` runs THEN the gallery tests (four combinations, toggles, language restored) pass, along with every existing test.

## Design

- `design_gallery_page.dart` keeps the `@RoutePage` page. It holds the theme choice, remembers the entry locale, and lays out a `CustomScrollView` with a pinned header of two `SegmentedPills` and a sliver list of sections.
- `gallery_sections.dart` holds one small widget per section. The demos are stateful: the button cycles, the mark replays, the headline replays through a key, and the shake bumps a counter.
- `tool/qa/screens_test.dart` loads the fonts with `FontLoader`. For each combination it renders the gallery in a tall surface, and Discover through the app harness, and saves each `RepaintBoundary` with `toImage`.

## Files

- modify lib/design/gallery/design_gallery_page.dart — page, pinned toggles, entry locale restored
- create lib/design/gallery/gallery_sections.dart — every component, with replayable demos
- create test/design/gallery_test.dart — four combinations, toggles, language restored
- create tool/qa/screens_test.dart — screenshot script for the gallery and Discover

## Tasks

- [x] T1: The gallery's sections and demos, with its language and theme pills, and widget tests
  - files: lib/design/gallery/design_gallery_page.dart, lib/design/gallery/gallery_sections.dart, test/design/gallery_test.dart
  - ac: AC1, AC2, AC4
  - verify: fvm flutter test test/design/gallery_test.dart test/features/discover/discover_route_test.dart
- [ ] T2: The screenshot script for visual QA
  - files: tool/qa/screens_test.dart
  - ac: AC3
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test && fvm flutter test tool/qa/screens_test.dart

## Risks

- R1: Switching `LocaleSettings` inside a test can wait on English's deferred library. Mitigation: tests load both languages inside `runAsync` first, as the app harness does.
- R2: The screenshots may reveal visual problems in widgets of earlier slices. Mitigation: small fixes go through a scope request with their reason; larger ones become their own change.

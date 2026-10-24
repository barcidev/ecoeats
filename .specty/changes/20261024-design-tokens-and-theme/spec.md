---
kind: standard
follows:
  - 20261024-project-skeleton
---

# Design tokens and theme

## Goal

The design system's foundations exist with the plan's final values: the «Mantel» (light) and «Fogón» (dark) palettes as a `ThemeExtension<EcoPalette>`, Fraunces and Instrument Sans bundled as variable fonts with the type scale, spacing, radii and motion tokens, and a light and dark `ThemeData` without ripples. Every later screen reads colors, type and motion only from here.

## Out of scope

- Design widgets (next changes) and wiring the theme into the app (routes change).
- Theme mode persistence (profile, agent A).

## Assumptions

- A1: Fonts come from google/fonts (OFL): `Fraunces[SOFT,WONK,opsz,wght].ttf`, its italic and `InstrumentSans[wdth,wght].ttf`, with their `OFL.txt`; the axes are set with `FontVariation`.
- A2: The palette has no red, so `ColorScheme.error` uses achiote; states that need an alarm use the illustration and the copy, not a color.
- A3: The display style is Fraunces at 48 with `opsz` 144, `SOFT` 100 and `wght` 500; `WONK` 1 is a separate style used only by the welcome headline.
- A4: `Motion.reduced(context)` reads `MediaQuery.disableAnimationsOf`; animated widgets switch to a crossfade when it is true.

## Acceptance criteria

- AC1: WHEN the light theme is built THEN its `EcoPalette` has paper #F4EEE4, raised #FBF7F0, ink #1E1B16, muted #6B6257, line #E2D8C9, achiote #C2410C, aguacate #4D6B2F, maíz #E3A72F and panela #8A5A2B; WHEN the dark theme is built THEN it has #14110E, #1E1A16, #F3ECE1, #A69C8F, #2E2822, #F06A2E, #8FB15A, #F2C14E and #B07A45.
- AC2: WHEN either theme is built THEN headings use the Fraunces family and body text the InstrumentSans family, body is 16/24, overlines carry a letter spacing of 1.4, and numeric styles use tabular figures.
- AC3: WHEN either theme is built THEN its splash factory is `NoSplash`, the scaffold background is the palette's paper and dividers are 1 px in the palette's line color.
- AC4: WHEN `MediaQuery.disableAnimations` is true THEN `Motion.reduced` returns true, and the motion tokens expose 160, 280, 480 and 900 ms, the emphasized `Cubic(0.2, 0, 0, 1)` curve and a 380/30 spring.

## Files

- create assets/fonts/** — Fraunces and Instrument Sans variable fonts with their OFL licenses
- modify pubspec.yaml — declare the font families
- create lib/design/tokens/palette.dart — EcoPalette ThemeExtension, light and dark values
- create lib/design/tokens/typography.dart — font families and type scale
- create lib/design/tokens/spacing.dart — spacing, radii and hairline
- create lib/design/tokens/motion.dart — durations, curves, spring, stagger, reduced motion
- create lib/design/theme.dart — light and dark ThemeData
- create test/design/tokens_test.dart — palette and motion tests
- create test/design/theme_test.dart — theme tests

## Tasks

- [x] T1: Bundle the fonts and define the type scale
  - files: assets/fonts/**, pubspec.yaml, lib/design/tokens/typography.dart, test/design/tokens_test.dart
  - ac: AC2
  - verify: fvm flutter analyze && fvm flutter test test/design
- [x] T2: Palette, spacing and motion tokens
  - files: lib/design/tokens/palette.dart, lib/design/tokens/spacing.dart, lib/design/tokens/motion.dart, test/design/tokens_test.dart
  - ac: AC1, AC4
  - verify: fvm flutter analyze && fvm flutter test test/design
- [ ] T3: Light and dark themes
  - files: lib/design/theme.dart, test/design/theme_test.dart
  - ac: AC2, AC3
  - verify: fvm flutter analyze && fvm flutter test

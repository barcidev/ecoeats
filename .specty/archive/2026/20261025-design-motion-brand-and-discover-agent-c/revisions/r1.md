---
kind: epic
---

# Design, motion, brand and Discover (agent C)

## Goal

The app gets the finished, hand-made feel the plan asks for, as agent C describes it. The shared design widgets move with springs, shimmer, blur and drawn illustrations behind the same API, and dish photos fly between screens, bending their corners and their names. The brand comes as a drawn logo, adaptive icons and a light and dark splash. Discover becomes a full-screen vertical walk through the dishes. A debug-only gallery shows every component in light and dark, in Spanish and in English, for visual QA.

## Out of scope

- The auth and profile screens (agent A) and the catalog screens (agent B). They pick up the new motion through the widgets they already use. The only changes inside their folders are the small additive scope requests of A3.
- The login success sweep and its route change (agent A, its A6). `EcoButton` only offers the expansion; whether auth uses it is agent A's call.
- The native platform folders and their base configuration (INTERNET permission, portrait, app name, predictive back, `CFBundleLocalizations`), which belong to phase 0.
- New design token values: palette, type scale, spacing and motion stay as phase 0 froze them.
- Store listing assets, release signing and publishing.
- Tablet layouts and landscape.

## Assumptions

- A1: The public API of every phase 0 design widget stays as it is. Slices only add optional named parameters, such as `EcoButton.success` and `onSuccess`, or new classes, such as `DishNameHero`. Every existing call in auth, catalog and their tests keeps compiling and passing.
  - impact: high
- A2: Each slice writes its own spec when it starts, against what `main` has by then. C8 and C9 wait until phase 0 has put `android/` and `ios/` on `main` (the open `20261025-android-platform` change and its iOS twin). The other slices need nothing more than the current `main`.
  - impact: high
- A3: Files outside agent C's paths change only through small, additive scope requests, each noted in the closing of its slice. The only planned ones: in C5, wrapping the dish name in `DishNameHero` in the carousel card, the menu row and the detail header (`features/dishes/presentation`); in C6, the one route test that pushes Discover, if its expectations change. `pubspec.yaml` stays untouched: the icon and splash generators read their own `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml`.
  - impact: high
- A4: The paper grain is generated at runtime once per process: a small tile of seeded random alpha built with `decodeImageFromPixels` and repeated with an `ImageShader`. There is no grain asset, and the texture never crawls between frames.
- A5: Discover walks the catalog's visible list (`visibleDishesProvider`), so it respects the active filter, search and order. It takes a snapshot of that list when it opens, so a refresh in the background never reorders the pages under the finger.
- A6: The first-time hint is stored in `shared_preferences` under one key. It hides for good after the first swipe or a tap on it. Its provider can be overridden in tests.
- A7: Haptics, light and few: a selection click when a `Pressable` fires, a light impact when a Discover page settles, a medium impact on each `Shake`, and a light impact when `EcoButton` succeeds.
- A8: With reduced motion, every signature motion becomes a crossfade or is skipped: springs, shimmer, Ken Burns, parallax, the circular reveal, the sliding pill and the hero bend. Layout, content and actions stay the same.
- A9: The brand export is a test file outside `test/`, run on purpose with `fvm flutter test tool/brand/export_brand_test.dart`. The regular test run never rewrites the PNGs. It draws `LogoMark` with the production painter and writes the 1024 px logo, plus the icon and splash sources derived from it, to `assets/brand/`.
- A10: The icon is the plate mark in ink with the achiote leaf, on the «Mantel» paper color. The Android adaptive icon has a separate foreground and background, plus a monochrome layer for themed icons. The splash shows the mark on «Mantel» paper in light mode and on «Fogón» paper in dark mode. The Android 12+ splash uses the same mark through its own API.
- A11: The design gallery switches language through `LocaleSettings` and puts the previous language back when it closes. It shows its components with real copy from the existing namespaces, so it needs no strings of its own.

## Acceptance criteria

- AC1: WHEN a `Pressable` is pressed THEN its child sinks with a spring and springs back on release, its callback runs once and a selection haptic plays; WHEN it has no callback THEN it ignores touches and reports itself as a disabled button; WHEN reduced motion is on THEN it does not scale.
- AC2: WHEN an `EcoButton` starts loading THEN its label fades out and the button narrows into a circle holding the plate spinner, and taps are ignored; WHEN loading ends without success THEN it widens back to its label; WHEN it is given `success` THEN the circle grows from the button until the achiote covers the screen, and `onSuccess` runs once it is covered.
- AC3: WHEN `PlateSpinner` spins THEN the rim chases itself with an eased tail, and with `progress` it shows a still partial rim; WHEN the `Shake` trigger changes THEN the child swings with damped spring swings, comes back exactly to rest and plays a medium haptic.
- AC4: WHEN an `EcoTextField` gains focus or holds text THEN its label settles from the input line up to the overline position, and the underline draws from the left in ink; WHEN it gets an error THEN the underline turns achiote and the error text slides in under it; WHEN the error clears THEN both go back; screen readers read the label, the value and the error.
- AC5: WHEN a `Skeleton` shows THEN a soft highlight sweeps across it in a loop, shared by every block on screen; WHEN `GrainOverlay` paints THEN the noise comes from the runtime tile and stays still between frames; WHEN `MaskRevealText` builds THEN each line slides up out of its own mask, 120 ms after the previous one.
- AC6: WHEN `LogoMark` animates THEN the plate rim draws itself as one stroke from the top and the leaf grows in at the end; WHEN `StateView` shows THEN it has its own drawing for empty, error, offline and rate-limited; WHEN it has a 429 cooldown THEN the action counts down as «m:ss» through the caller's label and enables itself at zero.
- AC7: WHEN a `Toast` shows THEN it drops from the top over a blurred backdrop, and the user can swipe it up to dismiss it; WHEN another one comes THEN it replaces the current one; screen readers announce it.
- AC8: WHEN a value of `SegmentedPills` is picked THEN one indicator slides and resizes from the old pill to the new one, and the row scrolls the pill into view; WHEN `RatingStars` shows 4.7 THEN the fifth star is filled 70 % of its width.
- AC9: WHEN a `DishImage` has no URL, is loading or fails THEN it shows the editorial placeholder: a gradient fixed by the dish name (same colors on every screen and launch), the drawn plate and the initials in Fraunces italic; WHEN the photo arrives THEN it fades in over 280 ms.
- AC10: WHEN a dish photo flies between screens THEN its corner radius changes smoothly from the source's to the destination's, and a name wrapped in `DishNameHero` flies along, blending its text style (size, weight, color) from card to detail.
- AC11: WHEN Discover opens from the banner THEN it grows as a circle from the touched point; it pages vertically, full screen, through the visible dishes; the active photo zooms slowly (Ken Burns); the text moves faster than the photo while dragging; a progress rail and a «04 / 12» counter follow the page; a light haptic plays when a page settles, and the next photo is precached.
- AC12: WHEN Discover opens for the first time THEN a swipe-up hint shows, and it never shows again after the first swipe or a tap on it; WHEN «Ver plato ↑» is tapped THEN the detail opens with the photo flying from Discover (hero source `discover`).
- AC13: WHEN reduced motion is on THEN Discover opens with a fade, shows no Ken Burns or text depth, and still pages, counts and opens the detail.
- AC14: WHEN `fvm flutter test tool/brand/export_brand_test.dart` runs THEN `assets/brand/` holds the 1024 px logo PNG and the icon and splash sources, drawn from `LogoMark`.
- AC15: WHEN the app is installed on Android THEN the launcher shows the adaptive icon, with a monochrome layer for themed icons, and the splash shows the mark on paper, light or dark, also through the Android 12+ splash API; WHEN it is installed on iOS THEN the icon and the light or dark launch screen show the same mark.
- AC16: WHEN the gallery opens in a debug build THEN every design component shows, and toggles switch between light and dark and between Spanish and English; WHEN the build is a release THEN the gallery route does not exist.
- AC17: WHEN `fvm flutter test` runs THEN widget tests pass for Pressable, the EcoButton states (idle, disabled, loading, success), the DishImage fallback, SegmentedPills and Discover with reduced motion, along with every existing test of agents A and B.

## Design

- `lib/design/widgets/`: same files, same public classes. The springs come from `Motion.spring` through `SpringSimulation` on a controller, not from a curve. The shimmer is one shared ticker exposed by an inherited `SkeletonScope`, so every block on a screen shines in step. The success expansion of `EcoButton` lives in an `OverlayEntry` that grows from the button's global rect.
- `lib/design/widgets/dish_hero.dart`: `DishHero` wraps its child in a radius marker that `flightShuttleBuilder` reads from both hero contexts and lerps along the flight. The new `DishNameHero` does the same with the `TextStyle`, through `TextStyle.lerp` in a `DefaultTextStyle`.
- `lib/design/painters/`: `LogoMark` draws its rim through `PathMetric.extractPath`, so `progress` is the length drawn. `PlateIllustration` gains an optional `kind` that adds each state's detail (an empty plate, a burnt mark, a cut cord, an hourglass) over the same plate.
- `lib/features/discover/`: `application/discover_hint.dart` (a persisted flag) and `presentation/discover_page.dart`, with private widgets for the page, the rail, the counter and the hint. `discover_route.dart` keeps `revealRoute` and adds a soft edge to the circle.
- `assets/brand/` holds the PNG sources. `tool/brand/export_brand_test.dart` renders them. `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml` at the root configure the generators, whose output lands in `android/` and `ios/`.
- Each slice is one module plus its tests whenever it can be, to stay within Specty's split limits.

## Slices

- C1: Press, button and spinner motion: spring Pressable with haptic, EcoButton that morphs into the loader and expands on success, PlateSpinner and spring Shake, with widget tests for Pressable and every EcoButton state
  - ac: AC1, AC2, AC3, AC17
- C2: Fields, headlines and surfaces: EcoTextField with animated label, underline and error, MaskRevealText, shared-shimmer Skeleton and runtime-noise GrainOverlay
  - ac: AC4, AC5
- C3: Painters and state views: stroke-drawn LogoMark, PlateIllustration with state details, and StateView with its drawings and 429 countdown
  - ac: AC6
- C4: Selection and feedback: blurred top Toast with swipe to dismiss, SegmentedPills with a sliding indicator and fractional RatingStars, with a SegmentedPills widget test
  - ac: AC7, AC8, AC17
  - depends: C1
- C5: Dish photos in flight: DishImage editorial placeholder with the 280 ms fade, DishHero shuttle bending the radius and DishNameHero blending the text style, wired into the catalog names, with a DishImage fallback test
  - ac: AC9, AC10, AC17
  - depends: C3
- C6: Discover: vertical pager over the visible list with Ken Burns, text depth, rail, counter, haptic and precache, the first-time hint, «Ver plato ↑» with the discover hero and the softened reveal, with a reduced-motion widget test
  - ac: AC11, AC12, AC13, AC17
  - depends: C1, C5
- C7: Brand export: the flutter test script that renders the 1024 px logo and the icon and splash sources into assets/brand
  - ac: AC14
  - depends: C3
- C8: Android icon and splash: adaptive and monochrome launcher icon and the light and dark splash, Android 12+ API included
  - ac: AC15
  - depends: C7
- C9: iOS icon and launch screen in light and dark
  - ac: AC15
  - depends: C8
- C10: Design gallery: every component in light, dark, Spanish and English, debug only
  - ac: AC16
  - depends: C2, C4, C5

## Risks

- R1: Agent A is changing auth screens that use `EcoButton`, `EcoTextField` and `Shake` at the same time. Mitigation: additive API only (A1), and every slice runs the whole test suite after merging `main` before it closes.
- R2: `flutter_launcher_icons` 0.14 or `flutter_native_splash` 2.4 may not match the Flutter 3.47 platform templates. Mitigation: run them in their slice and check on the simulator and emulator; if a generator fails, the slice writes the same resources by hand and notes it.
- R3: Blur and full-screen photos can drop frames. Mitigation: the blur is clipped to the toast's own shape, Ken Burns runs only on the active page, decoding follows the shown size, and Discover and the hero are profiled with `flutter run --profile`.
- R4: Names whose line breaks differ between card and detail may jump at the end of the flight. Mitigation: the shuttle lays out with the destination's width and line count, and C5 checks it on the longest seed name.
- R5: The native platforms may land on `main` late. Mitigation: C8 and C9 are the only slices that depend on them, and they come last but one.

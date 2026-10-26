---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C7
---

# Brand export: the flutter test script that renders the 1024 px logo and the icon and splash sources into assets/brand

## Goal

The brand's image files come out of the same painter the app draws its logo with, so the icon, the splash and the welcome mark can never drift apart. One script, run on purpose, writes the 1024 px logo and every source the icon and splash generators need into `assets/brand/`.

## Out of scope

- Running the icon and splash generators and the native resources they write (C8 and C9).
- Changing the mark's drawing (done in C3).

## Assumptions

- A1: The script is a test outside `test/` (`tool/brand/export_brand_test.dart`), run with `fvm flutter test tool/brand/export_brand_test.dart`. The regular test run never rewrites the PNGs, and they are committed.
  - impact: high
- A2: It renders `LogoMark` with its production painter through a `RepaintBoundary` at pixel ratio 1, inside `runAsync`, and writes PNG bytes. No font is involved: the mark is pure drawing.
- A3: `logo.png` is 1024 px and transparent, in «Mantel» ink and achiote. `icon.png` is 1024 px of opaque «Mantel» paper with the mark at 64 %, because iOS icons may not be transparent.
  - impact: high
- A4: `icon_foreground.png` is 1024 px and transparent with the mark at 56 %, inside the adaptive icon's 66 % safe zone. `icon_monochrome.png` is the same in a single color, for Android 13 themed icons.
  - impact: high
- A5: `splash.png` and `splash_dark.png` are 768 px (192 dp at 4x) and transparent, with the mark in «Mantel» and in «Fogón» colors. `splash_android12.png` and `splash_android12_dark.png` are 1152 px with the mark at 640 px, inside the 768 px circle that Android 12 keeps.
  - impact: high
- A6: A test in the same file checks what it wrote: the size of every file, transparency where expected, and an opaque icon.

## Acceptance criteria

- AC1: WHEN `fvm flutter test tool/brand/export_brand_test.dart` runs THEN `assets/brand/` holds `logo.png` at 1024 × 1024 with a transparent background, drawn by `LogoMark`.
- AC2: WHEN it runs THEN `assets/brand/` also holds the icon (opaque), adaptive foreground, monochrome, light and dark splash and Android 12 splash sources, each at its size and with the mark in the right colors and proportion.
- AC3: WHEN `fvm flutter test` runs THEN no brand file is written, and every existing test passes.

## Design

- One `_Asset` record per file: name, canvas size, mark size, background (null for transparent), rim and leaf colors. A loop pumps a `RepaintBoundary` with a `SizedBox` canvas and a centered `LogoMark`, captures it with `toImage`, and writes the PNG.
- A second test reads each PNG back with `instantiateImageCodec`, checks its size, and samples its corner pixel for transparency or for the opaque icon background.

## Files

- create tool/brand/export_brand_test.dart — renders and checks the brand sources
- create assets/brand/*.png — the rendered sources

## Tasks

- [ ] T1: The export script and its checks, and the rendered brand sources
  - files: tool/brand/export_brand_test.dart, assets/brand/*.png
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test tool/brand/export_brand_test.dart && fvm flutter analyze && fvm flutter test

## Risks

- R1: Anti-aliasing at the canvas edges could leave the icon's corners slightly transparent. Mitigation: the opaque icon paints its background over the whole canvas first, and the check samples the corner pixel.

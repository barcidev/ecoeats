---
kind: standard
epic: 20261025-design-motion-brand-and-discover-agent-c
slice: C2
---

# Fields, headlines and surfaces: EcoTextField with animated label, underline and error, MaskRevealText, shared-shimmer Skeleton and runtime-noise GrainOverlay

## Goal

Forms, headlines and placeholders get the motion and texture of printed matter. A field's label rests on its line and rises when the field is used, its underline draws itself in ink, and errors slide in under it. Headline lines rise out of masks that no longer clip their descenders. Skeletons shine with one light that crosses the whole screen. The paper grain is real noise made at runtime instead of scattered dots.

## Out of scope

- The auth forms and the catalog skeleton layouts themselves: they get the new motion through the widgets they already use.
- The other design widgets (slices C3 to C5).

## Assumptions

- A1: The public API of `EcoTextField`, `MaskRevealText`, `Skeleton` and `GrainOverlay` stays as it is; nothing is added to it.
  - impact: high
- A2: The label is always the same uppercase overline text, as today (existing tests find «CORREO»). At rest it sits larger on the input line. It rises and shrinks to the overline position when the field has focus or text. The hint shows only while the label is up and the field is empty.
  - impact: high
- A3: The field keeps a constant height whether the label rests or floats, so forms never jump. Only the error line below it grows and shrinks.
- A4: The shimmer is synchronized by the frame clock, not by a shared ancestor: every skeleton computes the highlight from the same frame timestamp and its own position on screen. Screens need no scope widget, and a band crosses the whole screen through the blocks in its way.
- A5: The grain tile is 128 × 128 pixels of seeded noise, generated once per process with `decodeImageFromPixels`. It is drawn one image pixel per physical pixel, tinted with the palette's ink at the overlay's opacity. Until the tile is ready, nothing is drawn.
- A6: With reduced motion, the label and underline jump to their state, the error appears without sliding, headline lines show at once, and skeletons are flat.

## Acceptance criteria

- AC1: WHEN an empty `EcoTextField` without focus shows THEN its uppercase label rests on the input line, larger than the overline; WHEN it gains focus or has text THEN the label moves up and shrinks to the overline position, and an ink underline draws itself from the left over the hairline; WHEN it loses focus while empty THEN both return; WHEN it gets an error THEN the label and the line turn achiote and the error slides in under the line; WHEN the error clears THEN it leaves and the colors return; the field's height above the error never changes.
- AC2: WHEN `MaskRevealText` builds THEN each line rises out of its own mask, 120 ms after the previous one, and ends fully visible with its descenders and accents unclipped; WHEN reduced motion is on THEN every line shows at once.
- AC3: WHEN several `Skeleton` blocks show THEN a highlight band sweeps across the screen in a loop, lighting each block as it passes, in step across blocks mounted at different times; WHEN reduced motion is on THEN they are flat and schedule no frames.
- AC4: WHEN `GrainOverlay` paints THEN it draws one runtime noise tile, made once and reused by every overlay, and it schedules no frames of its own, so the texture never crawls.
- AC5: WHEN `fvm flutter test` runs THEN tests for these four widgets pass, along with every existing test (auth forms and catalog skeletons included).

## Design

- `EcoTextField` becomes stateful. It keeps its own focus node and controller when none are given, and listens to them. One controller (`_float`) moves the label: translate and scale, from the top left. Another (`_ink`) grows the underline, painted by a small `CustomPainter` under the `TextField`, whose own borders are removed. The error goes through an `AnimatedSwitcher` with a slide and fade, inside an `AnimatedSize`.
- `MaskRevealText` clips each line with a custom clipper that reaches a third of the font size above and below the line box. Each line starts that much further down, so the mask hides it fully and no glyph is cut at rest.
- `Skeleton` paints through a small `RenderBox`. A ticker repaints it every frame, and the highlight's position comes from the frame timestamp modulo the period, mapped across the screen width and offset by the box's global position.
- `GrainOverlay` paints an `ImageShader` of the tile, repeated, scaled by 1 / devicePixelRatio and tinted with a `ColorFilter`. The tile's future is exposed `@visibleForTesting`.

## Files

- modify lib/design/widgets/eco_text_field.dart — resting and floating label, drawn underline, sliding error
- modify lib/design/widgets/mask_reveal_text.dart — masks that keep descenders and accents
- modify lib/design/widgets/skeleton.dart — highlight band shared through the frame clock
- modify lib/design/widgets/grain_overlay.dart — runtime noise tile through an image shader
- modify test/design/widgets/form_motion_test.dart — label, underline and error motion; headline masks
- create test/design/widgets/surfaces_test.dart — shimmer and grain

## Tasks

- [x] T1: EcoTextField with a resting and floating label, a drawn underline and a sliding error, with widget tests
  - files: lib/design/widgets/eco_text_field.dart, test/design/widgets/form_motion_test.dart
  - ac: AC1
  - verify: fvm flutter test test/design/widgets/form_motion_test.dart test/features/auth
- [ ] T2: MaskRevealText whose masks keep descenders and accents, with widget tests
  - files: lib/design/widgets/mask_reveal_text.dart, test/design/widgets/form_motion_test.dart
  - ac: AC2
  - verify: fvm flutter test test/design/widgets/form_motion_test.dart
- [ ] T3: Shared-shimmer Skeleton and runtime-noise GrainOverlay, with widget tests
  - files: lib/design/widgets/skeleton.dart, lib/design/widgets/grain_overlay.dart, test/design/widgets/surfaces_test.dart
  - ac: AC3, AC4, AC5
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter analyze && fvm flutter test

## Risks

- R1: Auth tests may type into fields, read errors or settle in ways the new motion changes. Mitigation: the label text, the error text and the `EditableText` stay; T1 runs the auth tests, and T3 the whole suite.
- R2: `decodeImageFromPixels` does not complete under fake async in widget tests. Mitigation: the overlay draws nothing until the tile is ready, and the grain test awaits the tile inside `runAsync`.
